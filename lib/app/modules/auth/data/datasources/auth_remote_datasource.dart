import 'dart:developer' as developer;

import '../../../../../core/errors/exceptions.dart';
import '../../../../../core/network/base_remote_service.dart';
import '../models/auth_session.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<AuthSession> login({required String email, required String password});

  /// Cria a conta (e dispara o e-mail de verificação no backend).
  /// NÃO autentica — o usuário precisa confirmar o código antes.
  Future<UserModel> register({
    required String email,
    required String password,
    required String fullName,
    required String displayName,
  });

  /// Confirma o código de 6 dígitos e devolve a sessão (tokens) já autenticada.
  Future<AuthSession> verifyEmail({
    required String email,
    required String code,
  });

  /// Pede um novo código de verificação para o e-mail informado.
  Future<void> resendCode({required String email});

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
    } on AuthException catch (e, st) {
      developer.log('login: AuthException', name: 'AuthRemoteDataSource', error: e, stackTrace: st);
      // 401 no login = credenciais inválidas (semântica de domínio).
      throw AuthException('Email ou senha inválidos.');
    } on ServerException catch (e, st) {
      developer.log('login: ServerException', name: 'AuthRemoteDataSource', error: e, stackTrace: st);
      // 400/403 (ex.: e-mail não verificado) volta com a mensagem do backend.
      throw AuthException(e.message);
    }
  }

  @override
  Future<UserModel> register({
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
    } on ServerException catch (e, st) {
      developer.log('register: ServerException', name: 'AuthRemoteDataSource', error: e, stackTrace: st);
      // Validação / e-mail duplicado vem como 400.
      throw AuthException(e.message);
    }
  }

  @override
  Future<AuthSession> verifyEmail({
    required String email,
    required String code,
  }) async {
    try {
      final json = await postMap(
        '/api/auth/verify-email',
        body: {'email': email, 'code': code},
        anonymous: true,
      );
      return AuthSession.fromLoginResponse(json);
    } on ServerException catch (e, st) {
      developer.log('verifyEmail: ServerException', name: 'AuthRemoteDataSource', error: e, stackTrace: st);
      // Código inválido / expirado / muitas tentativas → 400 com mensagem.
      throw AuthException(e.message);
    }
  }

  @override
  Future<void> resendCode({required String email}) async {
    await postVoid(
      '/api/auth/resend-code',
      body: {'email': email},
      anonymous: true,
    );
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
    } catch (e, st) {
      developer.log('logout silencioso', name: 'AuthRemoteDataSource', error: e, stackTrace: st);
      // Logout silencioso — o que importa é apagar a sessão local.
    }
  }
}
