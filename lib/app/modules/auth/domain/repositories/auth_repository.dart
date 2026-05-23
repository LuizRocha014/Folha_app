import 'package:dartz/dartz.dart';
import '../../../../../core/errors/failures.dart';
import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<Either<Failure, UserEntity>> login({
    required String email,
    required String password,
  });

  Future<Either<Failure, UserEntity>> signup({
    required String email,
    required String password,
    required String fullName,
    required String displayName,
  });

  /// Restaura a sessão a partir do storage seguro (auto-login após reabrir o app).
  Future<Either<Failure, UserEntity?>> restoreSession();

  Future<Either<Failure, void>> logout();

  Future<Either<Failure, UserEntity?>> currentUser();

  /// Habilita biometria salvando email+senha no secure storage para uso posterior.
  Future<Either<Failure, void>> enableBiometric({
    required String email,
    required String password,
  });

  Future<Either<Failure, void>> disableBiometric();

  Future<bool> isBiometricEnabled();

  /// Login disparado APÓS a biometria autenticar — usa credencial salva no Keystore.
  Future<Either<Failure, UserEntity>> loginWithBiometric();
}
