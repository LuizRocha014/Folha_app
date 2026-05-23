import '../../../../../core/errors/exceptions.dart';
import '../../../../../core/network/base_remote_service.dart';
import '../models/auth_session.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<AuthSession> login({required String email, required String password});

  Future<UserModel> signup({
    required String email,
    required String password,
    required String fullName,
    required String displayName,
  });

  Future<UserModel> currentUserMe();

  Future<void> logout({required String refreshToken});
}

class AuthRemoteDataSourceImpl extends BaseRemoteService
    implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl({required super.http});

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {  
    try {
      final json = await postMap(
        '/api/auth/login',
        body: {'email': email, 'password': password},
        anonymous: true,
      );
      return AuthSession.fromLoginResponse(json);
    } on AuthException {
      // 401 no login = credenciais inválidas (semântica de domínio).
      throw AuthException('Email ou senha inválidos.');
    } on ServerException catch (e) {
      // 400 com payload de validação volta como ServerException — re-traduz.
      throw AuthException(e.message);
    }
  }

  @override
  Future<UserModel> signup({
    required String email,
    required String password,
    required String fullName,
    required String displayName,
  }) async {
    try {
      final json = await postMap(
        '/api/users',
        body: {
          'email': email,
          'password': password,
          'fullName': fullName,
          'displayName': displayName,
        },
        anonymous: true,
      );
      return UserModel.fromJson(json);
    } on ServerException catch (e) {
      // Validation / email duplicado vem como 400.
      throw AuthException(e.message);
    }
  }

  @override
  Future<UserModel> currentUserMe() async {
    final json = await getMap('/api/users/me');
    return UserModel.fromJson(json);
  }

  @override
  Future<void> logout({required String refreshToken}) async {
    try {
      await postVoid(
        '/api/auth/logout',
        body: {'refreshToken': refreshToken},
        anonymous: true,
      );
    } catch (_) {
      // Logout silencioso — o que importa é apagar a sessão local.
    }
  }
}
