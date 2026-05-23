import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../../core/errors/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class EnableBiometricParams extends Equatable {
  final String email;
  final String password;
  const EnableBiometricParams({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

class EnableBiometricUseCase implements UseCase<void, EnableBiometricParams> {
  final AuthRepository repository;
  EnableBiometricUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(EnableBiometricParams params) =>
      repository.enableBiometric(email: params.email, password: params.password);
}

class DisableBiometricUseCase implements UseCase<void, NoParams> {
  final AuthRepository repository;
  DisableBiometricUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(NoParams params) => repository.disableBiometric();
}

class LoginWithBiometricUseCase implements UseCase<UserEntity, NoParams> {
  final AuthRepository repository;
  LoginWithBiometricUseCase(this.repository);

  @override
  Future<Either<Failure, UserEntity>> call(NoParams params) =>
      repository.loginWithBiometric();
}

class RestoreSessionUseCase implements UseCase<UserEntity?, NoParams> {
  final AuthRepository repository;
  RestoreSessionUseCase(this.repository);

  @override
  Future<Either<Failure, UserEntity?>> call(NoParams params) => repository.restoreSession();
}
