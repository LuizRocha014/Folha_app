import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import '../config/app_config.dart';
import '../errors/exceptions.dart';
import '../security/device_info_service.dart';
import '../security/secure_storage_service.dart';

/// Resposta crua do `FolhaHttpClient`.
///
/// `body` já vem decodificado para `Map<String, dynamic>` / `List<dynamic>` /
/// `null` quando o `Content-Type` é JSON. `rawBody` mantém a string original.
class HttpResponseData {
  HttpResponseData({
    required this.statusCode,
    required this.body,
    required this.rawBody,
  });

  final int statusCode;
  final dynamic body;
  final String rawBody;

  bool get isSuccess => statusCode >= 200 && statusCode < 300;
}

/// Cliente HTTP do app — embrulha `dart:io HttpClient`.
///
/// O que ele faz por você:
/// - Injeta `Authorization: Bearer …` em toda request autenticada.
/// - Anexa `X-Device-Id` (necessário para o backend amarrar o refresh ao device).
/// - Em 401, dispara `/api/auth/refresh` uma única vez e re-tenta a request original.
///   Requests concorrentes que caem em 401 ao mesmo tempo compartilham o mesmo
///   `Completer<String?>` — não disparam refresh múltiplo.
/// - Mapeia falhas de socket/timeout para `NetworkException`.
///
/// O que ele NÃO faz:
/// - Certificate pinning. O app confia no trust store do SO. Verifique se isso
///   é aceitável antes de subir para produção.
class FolhaHttpClient {
  FolhaHttpClient({
    required this.secureStorage,
    required this.deviceInfo,
    String? baseUrl,
    Duration? timeout,
    this.onUnauthorized,
  })  : _baseUrl = baseUrl ?? AppConfig.I.apiBaseUrl,
        _timeout = timeout ?? AppConfig.I.apiTimeout,
        _io = HttpClient()
          ..connectionTimeout = timeout ?? AppConfig.I.apiTimeout;

  final SecureStorageService secureStorage;
  final DeviceInfoService deviceInfo;

  /// Disparado quando o refresh falha — o app deve forçar logout/limpar sessão.
  final Future<void> Function()? onUnauthorized;

  final String _baseUrl;
  final Duration _timeout;
  final HttpClient _io;

  Completer<String?>? _refreshing;
  String? _cachedDeviceId;

  Future<String> _deviceId() async {
    return _cachedDeviceId ??= await deviceInfo.getOrCreateDeviceId();
  }

  // ── API pública ─────────────────────────────────────────────────────────

  /// Executa uma request. Se `anonymous == false`, anexa o bearer e tenta
  /// refresh em caso de 401.
  Future<HttpResponseData> send(
    String method,
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    bool anonymous = false,
  }) async {
    if (anonymous) {
      return _execute(method, path, body: body, query: query, token: null);
    }

    final token = await secureStorage.readAccessToken();
    final first = await _execute(method, path, body: body, query: query, token: token);
    if (first.statusCode != 401) return first;

    // Evita loop: a própria chamada de refresh não tenta refresh.
    if (path.contains('/api/auth/refresh')) return first;

    final newToken = await _refreshAccessToken();
    if (newToken == null) {
      await onUnauthorized?.call();
      return first;
    }
    return _execute(method, path, body: body, query: query, token: newToken);
  }

  void dispose() => _io.close(force: true);

  // ── Implementação ───────────────────────────────────────────────────────

  Future<HttpResponseData> _execute(
    String method,
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    String? token,
  }) async {
    final uri = _buildUri(path, query);
    try {
      final req = await _io.openUrl(method, uri).timeout(_timeout);
      req.headers.set(HttpHeaders.contentTypeHeader, 'application/json; charset=utf-8');
      req.headers.set(HttpHeaders.acceptHeader, 'application/json');
      if (token != null && token.isNotEmpty) {
        req.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      }
      req.headers.set('X-Device-Id', await _deviceId());

      if (body != null) {
        req.add(utf8.encode(jsonEncode(body)));
      }

      final response = await req.close().timeout(_timeout);
      final raw = await response.transform(utf8.decoder).join();
      final parsed = _tryDecode(raw, response.headers.contentType?.mimeType);
      return HttpResponseData(
        statusCode: response.statusCode,
        body: parsed,
        rawBody: raw,
      );
    } on SocketException catch (e, st) {
      developer.log('SocketException $method $uri', name: 'FolhaHttpClient', error: e, stackTrace: st);
      throw NetworkException('Sem conexão com a Folha.Api.');
    } on HttpException catch (e, st) {
      developer.log('HttpException $method $uri', name: 'FolhaHttpClient', error: e, stackTrace: st);
      throw NetworkException('Falha na comunicação com a Folha.Api.');
    } on TimeoutException catch (e, st) {
      developer.log('TimeoutException $method $uri', name: 'FolhaHttpClient', error: e, stackTrace: st);
      throw NetworkException('Tempo esgotado ao falar com a Folha.Api.');
    }
  }

  Uri _buildUri(String path, Map<String, dynamic>? query) {
    final base = Uri.parse(_baseUrl);
    final suffix = path.startsWith('/') ? path : '/$path';
    final fullPath = '${base.path}$suffix'.replaceAll('//', '/');
    final qp = query?.map((k, v) => MapEntry(k, v?.toString() ?? ''));
    return base.replace(path: fullPath, queryParameters: qp);
  }

  dynamic _tryDecode(String raw, String? mime) {
    if (raw.isEmpty) return null;
    if (mime != null && !mime.contains('json')) return null;
    try {
      return jsonDecode(raw);
    } catch (e, st) {
      developer.log('jsonDecode falhou (mime=$mime)', name: 'FolhaHttpClient', error: e, stackTrace: st);
      return null;
    }
  }

  Future<String?> _refreshAccessToken() {
    if (_refreshing != null) return _refreshing!.future;
    final completer = Completer<String?>();
    _refreshing = completer;

    () async {
      try {
        final refresh = await secureStorage.readRefreshToken();
        if (refresh == null || refresh.isEmpty) {
          completer.complete(null);
          return;
        }
        final res = await _execute(
          'POST',
          '/api/auth/refresh',
          body: {'refreshToken': refresh},
          token: null,
        );
        if (!res.isSuccess || res.body is! Map) {
          completer.complete(null);
          return;
        }
        final data = res.body as Map<String, dynamic>;
        final access = data['accessToken'] as String?;
        final newRefresh = data['refreshToken'] as String?;
        final expiresIso = data['refreshTokenExpiresAt'] as String?;
        if (access == null || newRefresh == null) {
          completer.complete(null);
          return;
        }
        final expiresAt =
            expiresIso != null ? DateTime.tryParse(expiresIso) : null;
        if (expiresAt != null) {
          final userJson = await secureStorage.readUserJson() ?? '{}';
          await secureStorage.saveSession(
            accessToken: access,
            refreshToken: newRefresh,
            userJson: userJson,
            refreshExpiresAt: expiresAt,
          );
        } else {
          await secureStorage.updateAccessToken(access);
        }
        completer.complete(access);
      } catch (e, st) {
        developer.log('refresh token falhou', name: 'FolhaHttpClient', error: e, stackTrace: st);
        completer.complete(null);
      } finally {
        _refreshing = null;
      }
    }();

    return completer.future;
  }
}
