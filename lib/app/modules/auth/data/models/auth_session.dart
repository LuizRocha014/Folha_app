import 'user_model.dart';

/// Resposta do `POST /api/auth/login` e `/api/auth/refresh`.
class AuthSession {
  final String accessToken;
  final String refreshToken;
  final DateTime refreshTokenExpiresAt;
  final int expiresInMinutes;
  final UserModel user;

  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.refreshTokenExpiresAt,
    required this.expiresInMinutes,
    required this.user,
  });

  factory AuthSession.fromLoginResponse(Map<String, dynamic> json) {
    return AuthSession(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      refreshTokenExpiresAt:
          DateTime.tryParse((json['refreshTokenExpiresAt'] as String?) ?? '') ??
              DateTime.now().add(const Duration(days: 30)),
      expiresInMinutes: (json['expiresInMinutes'] as int?) ?? 120,
      user: UserModel.fromLoginResponse(json),
    );
  }
}
