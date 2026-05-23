import 'dart:convert';
import 'package:sqflite_sqlcipher/sqflite.dart';
import '../../../../../core/database/local_database.dart';
import '../../../../../core/security/secure_storage_service.dart';
import '../models/user_model.dart';

/// Datasource local de auth — usuário cacheado no banco encriptado + tokens no Keychain.
class AuthLocalDataSource {
  AuthLocalDataSource({
    required this.secureStorage,
    this.database,
  });

  final SecureStorageService secureStorage;

  /// Pode ser null antes do primeiro login. Após login, é aberto e atribuído.
  LocalDatabase? database;

  Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
    required DateTime refreshExpiresAt,
    required UserModel user,
  }) async {
    await secureStorage.saveSession(
      accessToken: accessToken,
      refreshToken: refreshToken,
      userJson: jsonEncode(user.toJson()),
      refreshExpiresAt: refreshExpiresAt,
    );
  }

  Future<UserModel?> readCachedUser() async {
    final raw = await secureStorage.readUserJson();
    if (raw == null) return null;
    try {
      return UserModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<String?> readAccessToken() => secureStorage.readAccessToken();
  Future<String?> readRefreshToken() => secureStorage.readRefreshToken();

  Future<void> upsertUserInDb(UserModel user) async {
    final db = database;
    if (db == null) return;
    final now = DateTime.now().toUtc().toIso8601String();
    await db.raw.insert(
      'users',
      {
        'id': user.id,
        'email': user.email,
        'full_name': user.fullName,
        'display_name': user.displayName,
        'avatar_url': user.avatarUrl,
        'currency_code': user.currencyCode,
        'is_active': 1,
        'created_at': now,
        'updated_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> clearSession() => secureStorage.clearSession();
}
