import 'dart:developer' as developer;

import 'package:dartz/dartz.dart';
import '../../../../../core/database/local_database.dart';
import '../../../../../core/errors/exceptions.dart';
import '../../../../../core/errors/failures.dart';
import '../../../../../core/security/biometric_service.dart';
import '../../../../../core/security/secure_storage_service.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required this.remote,
    required this.local,
    required this.secureStorage,
    required this.biometric,
    this.onDatabaseOpened,
  });

  final AuthRemoteDataSource remote;
  final AuthLocalDataSource local;
  final SecureStorageService secureStorage;
  final BiometricService biometric;

  /// Callback chamado quando abre/cria o banco encriptado do user (`LocalDatabase`).
  /// `InitialBinding` registra o resultado no Get container.
  final Future<LocalDatabase> Function(String userId)? onDatabaseOpened;

  @override
  Future<Either<Failure, UserEntity>> login({
    required String email,
    required String password,
  }) async {
    try {
      final session = await remote.login(email: email, password: password);
      await local.saveSession(
        accessToken: session.accessToken,
        refreshToken: session.refreshToken,
        refreshExpiresAt: session.refreshTokenExpiresAt,
        user: session.user,
      );
      if (onDatabaseOpened != null) {
        local.database = await onDatabaseOpened!(session.user.id);
        await local.upsertUserInDb(session.user);
      }
      return Right(session.user);
    } on AuthException catch (e, st) {
      developer.log('login: AuthException', name: 'AuthRepository', error: e, stackTrace: st);
      return Left(AuthFailure(e.message));
    } on NetworkException catch (e, st) {
      developer.log('login: NetworkException', name: 'AuthRepository', error: e, stackTrace: st);
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e, st) {
      developer.log('login: ServerException', name: 'AuthRepository', error: e, stackTrace: st);
      return Left(ServerFailure(e.message));
    } catch (e, st) {
      developer.log('login: erro inesperado', name: 'AuthRepository', error: e, stackTrace: st);
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, UserEntity>> signup({
    required String email,
    required String password,
    required String fullName,
    required String displayName,
  }) async {
    try {
      final created = await remote.signup(
        email: email,
        password: password,
        fullName: fullName,
        displayName: displayName,
      );
      // Faz login automático após signup pra capturar tokens.
      return await login(email: email, password: password).then((either) {
        return either.fold((f) => Right(created), Right.new);
      });
    } on AuthException catch (e, st) {
      developer.log('signup: AuthException', name: 'AuthRepository', error: e, stackTrace: st);
      return Left(AuthFailure(e.message));
    } on NetworkException catch (e, st) {
      developer.log('signup: NetworkException', name: 'AuthRepository', error: e, stackTrace: st);
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e, st) {
      developer.log('signup: ServerException', name: 'AuthRepository', error: e, stackTrace: st);
      return Left(ServerFailure(e.message));
    } catch (e, st) {
      developer.log('signup: erro inesperado', name: 'AuthRepository', error: e, stackTrace: st);
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, UserEntity?>> restoreSession() async {
    try {
      final user = await local.readCachedUser();
      if (user == null) return const Right(null);

      // Reabre o banco encriptado.
      if (onDatabaseOpened != null) {
        local.database = await onDatabaseOpened!(user.id);
      }

      // Tenta validar com a API; offline cai no cache.
      try {
        final fresh = await remote.currentUserMe();
        await local.saveSession(
          accessToken: (await local.readAccessToken()) ?? '',
          refreshToken: (await local.readRefreshToken()) ?? '',
          refreshExpiresAt: (await secureStorage.readRefreshExpiresAt()) ??
              DateTime.now().add(const Duration(days: 30)),
          user: fresh,
        );
        await local.upsertUserInDb(fresh);
        return Right(fresh);
      } on NetworkException catch (e, st) {
        developer.log('restoreSession: NetworkException (cai offline)', name: 'AuthRepository', error: e, stackTrace: st);
        return Right(user); // offline OK
      } on AuthException catch (e, st) {
        developer.log('restoreSession: AuthException (limpando sessão)', name: 'AuthRepository', error: e, stackTrace: st);
        await local.clearSession();
        return const Right(null);
      }
    } catch (e, st) {
      developer.log('restoreSession: erro inesperado', name: 'AuthRepository', error: e, stackTrace: st);
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      final refresh = await local.readRefreshToken();
      if (refresh != null && refresh.isNotEmpty) {
        await remote.logout(refreshToken: refresh);
      }
      final user = await local.readCachedUser();
      if (user != null) {
        await secureStorage.clearBiometricPassword(user.id);
      }
      await local.clearSession();
      await secureStorage.setBiometricEnabled(false);
      return const Right(null);
    } catch (e, st) {
      developer.log('logout', name: 'AuthRepository', error: e, stackTrace: st);
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, UserEntity?>> currentUser() async {
    try {
      final cached = await local.readCachedUser();
      return Right(cached);
    } catch (e, st) {
      developer.log('currentUser', name: 'AuthRepository', error: e, stackTrace: st);
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, void>> enableBiometric({
    required String email,
    required String password,
  }) async {
    try {
      if (!await biometric.isAvailable()) {
        return const Left(ValidationFailure('Biometria não disponível neste device.'));
      }
      final ok = await biometric.authenticate(
        reason: 'Confirme sua biometria para habilitar o login rápido.',
      );
      if (!ok) return const Left(AuthFailure('Biometria não autenticada.'));

      final user = await local.readCachedUser();
      if (user == null) return const Left(AuthFailure('Nenhum usuário logado.'));

      await secureStorage.saveBiometricPassword(user.id, email, password);
      await secureStorage.setBiometricEnabled(true);
      return const Right(null);
    } catch (e, st) {
      developer.log('enableBiometric', name: 'AuthRepository', error: e, stackTrace: st);
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, void>> disableBiometric() async {
    try {
      final user = await local.readCachedUser();
      if (user != null) {
        await secureStorage.clearBiometricPassword(user.id);
      }
      await secureStorage.setBiometricEnabled(false);
      return const Right(null);
    } catch (e, st) {
      developer.log('disableBiometric', name: 'AuthRepository', error: e, stackTrace: st);
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<bool> isBiometricEnabled() async {
    if (!await secureStorage.isBiometricEnabled()) return false;
    return biometric.isAvailable();
  }

  @override
  Future<Either<Failure, UserEntity>> loginWithBiometric() async {
    try {
      if (!await biometric.isAvailable()) {
        return const Left(ValidationFailure('Biometria não disponível.'));
      }
      final user = await local.readCachedUser();
      if (user == null) {
        return const Left(AuthFailure('Nenhuma conta salva neste device.'));
      }
      final creds = await secureStorage.readBiometricPassword(user.id);
      if (creds == null) {
        return const Left(AuthFailure('Senha biométrica não configurada.'));
      }
      final ok = await biometric.authenticate(reason: 'Entrar na Folha');
      if (!ok) return const Left(AuthFailure('Biometria não confirmada.'));

      return await login(email: creds.$1, password: creds.$2);
    } catch (e, st) {
      developer.log('loginWithBiometric', name: 'AuthRepository', error: e, stackTrace: st);
      return const Left(UnknownFailure());
    }
  }
}
