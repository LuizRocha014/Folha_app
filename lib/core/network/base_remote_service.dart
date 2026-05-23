import '../errors/exceptions.dart';
import 'folha_http_client.dart';

/// Classe base de **todos os datasources remotos**.
///
/// Por que existe: cada datasource quer fazer GET/POST/PUT/DELETE, parsear JSON
/// e converter status != 2xx em exceptions tipadas. Em vez de repetir try/catch
/// e `if (statusCode != 200)` em cada datasource, expomos verbos prontos.
///
/// Use assim:
/// ```dart
/// class BillRemoteDataSourceImpl extends BaseRemoteService
///     implements BillRemoteDataSource {
///   BillRemoteDataSourceImpl({required super.http});
///
///   @override
///   Future<List<Map<String, dynamic>>> listRaw({DateTime? modifiedSince}) {
///     return getList('/api/bills', query: {
///       if (modifiedSince != null) 'modifiedSince': modifiedSince.toUtc().toIso8601String(),
///     });
///   }
/// }
/// ```
///
/// Erros traduzidos automaticamente:
/// - 401          → `AuthException`
/// - 4xx          → `ServerException` (com a mensagem do backend quando houver)
/// - 5xx          → `ServerException`
/// - timeout/socket → `NetworkException` (jogado pelo `FolhaHttpClient`)
abstract class BaseRemoteService {
  BaseRemoteService({required this.http});

  final FolhaHttpClient http;

  // ── GET ──────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getMap(
    String path, {
    Map<String, dynamic>? query,
    bool anonymous = false,
  }) async {
    final res = await http.send('GET', path, query: query, anonymous: anonymous);
    _ensureSuccess(res, path);
    return _expectMap(res.body, path);
  }

  Future<List<Map<String, dynamic>>> getList(
    String path, {
    Map<String, dynamic>? query,
    bool anonymous = false,
  }) async {
    final res = await http.send('GET', path, query: query, anonymous: anonymous);
    _ensureSuccess(res, path);
    return _expectList(res.body, path);
  }

  // ── POST ─────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> postMap(
    String path, {
    Object? body,
    bool anonymous = false,
    Set<int> successStatuses = const {200, 201},
  }) async {
    final res = await http.send('POST', path, body: body, anonymous: anonymous);
    _ensureSuccess(res, path, successStatuses: successStatuses);
    return _expectMap(res.body, path);
  }

  Future<void> postVoid(
    String path, {
    Object? body,
    bool anonymous = false,
    Set<int> successStatuses = const {200, 201, 204},
  }) async {
    final res = await http.send('POST', path, body: body, anonymous: anonymous);
    _ensureSuccess(res, path, successStatuses: successStatuses);
  }

  // ── PUT ──────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> putMap(
    String path, {
    Object? body,
    bool anonymous = false,
    Set<int> successStatuses = const {200},
  }) async {
    final res = await http.send('PUT', path, body: body, anonymous: anonymous);
    _ensureSuccess(res, path, successStatuses: successStatuses);
    return _expectMap(res.body, path);
  }

  // ── DELETE ───────────────────────────────────────────────────────────────

  Future<void> deleteVoid(
    String path, {
    bool anonymous = false,
    Set<int> successStatuses = const {200, 204},
  }) async {
    final res = await http.send('DELETE', path, anonymous: anonymous);
    _ensureSuccess(res, path, successStatuses: successStatuses);
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  void _ensureSuccess(
    HttpResponseData res,
    String path, {
    Set<int> successStatuses = const {200},
  }) {
    if (successStatuses.contains(res.statusCode)) return;

    final apiMsg = _readErrorMessage(res.body);
    final status = res.statusCode;
    if (status == 401) {
      throw AuthException(apiMsg ?? 'Sessão expirada.');
    }
    if (status >= 400 && status < 500) {
      throw ServerException(apiMsg ?? 'Requisição inválida em $path (status $status).');
    }
    throw ServerException(apiMsg ?? 'Erro no servidor em $path (status $status).');
  }

  String? _readErrorMessage(dynamic body) {
    if (body is Map<String, dynamic>) {
      final candidate = body['error'] ?? body['message'] ?? body['title'];
      if (candidate is String && candidate.isNotEmpty) return candidate;
    }
    return null;
  }

  Map<String, dynamic> _expectMap(dynamic body, String path) {
    if (body is Map<String, dynamic>) return body;
    throw ServerException('Resposta inesperada (esperado JSON object) em $path.');
  }

  List<Map<String, dynamic>> _expectList(dynamic body, String path) {
    if (body is List) return body.cast<Map<String, dynamic>>();
    throw ServerException('Resposta inesperada (esperado JSON array) em $path.');
  }
}
