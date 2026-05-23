import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Wrapper sobre `flutter_secure_storage` — Keychain (iOS) / EncryptedSharedPreferences (Android).
///
/// Chaves:
/// - `auth.access_token` — JWT atual
/// - `auth.refresh_token` — refresh token (longa duração)
/// - `auth.user_json`     — payload do usuário logado (id, email, full_name, display_name)
/// - `auth.refresh_expires_at` — ISO8601 da expiração do refresh
/// - `device.id`          — UUID gerado uma vez por instalação
/// - `biometric.enabled`  — "1" se o usuário habilitou login com biometria
/// - `biometric.password.<userId>` — senha do usuário criptografada pelo keystore (só se biometria ativada)
/// - `db.key.<userId>`    — chave AES-256 do banco SQLCipher daquele usuário
class SecureStorageService {
  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device),
            );

  final FlutterSecureStorage _storage;

  // ── Auth tokens ────────────────────────────────────────────────
  static const _kAccessToken = 'auth.access_token';
  static const _kRefreshToken = 'auth.refresh_token';
  static const _kUserJson = 'auth.user_json';
  static const _kRefreshExpiresAt = 'auth.refresh_expires_at';

  Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
    required String userJson,
    required DateTime refreshExpiresAt,
  }) async {
    await Future.wait([
      _storage.write(key: _kAccessToken, value: accessToken),
      _storage.write(key: _kRefreshToken, value: refreshToken),
      _storage.write(key: _kUserJson, value: userJson),
      _storage.write(key: _kRefreshExpiresAt, value: refreshExpiresAt.toIso8601String()),
    ]);
  }

  Future<String?> readAccessToken() => _storage.read(key: _kAccessToken);
  Future<String?> readRefreshToken() => _storage.read(key: _kRefreshToken);
  Future<String?> readUserJson() => _storage.read(key: _kUserJson);
  Future<DateTime?> readRefreshExpiresAt() async {
    final iso = await _storage.read(key: _kRefreshExpiresAt);
    return iso == null ? null : DateTime.tryParse(iso);
  }

  Future<void> updateAccessToken(String accessToken) =>
      _storage.write(key: _kAccessToken, value: accessToken);

  Future<void> clearSession() async {
    await Future.wait([
      _storage.delete(key: _kAccessToken),
      _storage.delete(key: _kRefreshToken),
      _storage.delete(key: _kUserJson),
      _storage.delete(key: _kRefreshExpiresAt),
    ]);
  }

  // ── Onboarding ────────────────────────────────────────────────
  static const _kWelcomeSeen = 'welcome.seen';

  /// `true` quando o usuário já viu a Welcome ao menos uma vez.
  /// Depois disso o app pula direto pro login.
  Future<bool> hasSeenWelcome() async =>
      (await _storage.read(key: _kWelcomeSeen)) == '1';

  Future<void> markWelcomeSeen() =>
      _storage.write(key: _kWelcomeSeen, value: '1');

  // ── Device id ──────────────────────────────────────────────────
  static const _kDeviceId = 'device.id';

  Future<String?> readDeviceId() => _storage.read(key: _kDeviceId);
  Future<void> saveDeviceId(String id) => _storage.write(key: _kDeviceId, value: id);

  // ── Biometric ──────────────────────────────────────────────────
  static const _kBiometricEnabled = 'biometric.enabled';
  static String _biometricPwdKey(String userId) => 'biometric.password.$userId';

  Future<bool> isBiometricEnabled() async =>
      (await _storage.read(key: _kBiometricEnabled)) == '1';

  Future<void> setBiometricEnabled(bool enabled) async {
    if (enabled) {
      await _storage.write(key: _kBiometricEnabled, value: '1');
    } else {
      await _storage.delete(key: _kBiometricEnabled);
    }
  }

  Future<void> saveBiometricPassword(String userId, String email, String password) async {
    final payload = jsonEncode({'email': email, 'password': password});
    await _storage.write(key: _biometricPwdKey(userId), value: payload);
  }

  Future<(String email, String password)?> readBiometricPassword(String userId) async {
    final raw = await _storage.read(key: _biometricPwdKey(userId));
    if (raw == null) return null;
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return (map['email'] as String, map['password'] as String);
  }

  Future<void> clearBiometricPassword(String userId) =>
      _storage.delete(key: _biometricPwdKey(userId));

  // ── Database key ───────────────────────────────────────────────
  static String _dbKeyKey(String userId) => 'db.key.$userId';

  Future<String?> readDatabaseKey(String userId) => _storage.read(key: _dbKeyKey(userId));
  Future<void> saveDatabaseKey(String userId, String hexKey) =>
      _storage.write(key: _dbKeyKey(userId), value: hexKey);
  Future<void> clearDatabaseKey(String userId) =>
      _storage.delete(key: _dbKeyKey(userId));

  /// Apaga TUDO — usado em "esquecer este dispositivo" / desinstalar lógico.
  Future<void> nuke() => _storage.deleteAll();
}
