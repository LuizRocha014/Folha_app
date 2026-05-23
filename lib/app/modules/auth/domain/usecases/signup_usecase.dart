import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../../core/errors/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class SignupParams extends Equatable {
  final String email;
  final String password;
  final String fullName;
  final String displayName;
  // legados (UI atual coleta — não enviamos pra API ainda)
  final String? cpf;
  final DateTime? birthDate;

  const SignupParams({
    required this.email,
    required this.password,
    required this.fullName,
    required this.displayName,
    this.cpf,
    this.birthDate,
  });

  @override
  List<Object?> get props => [email, password, fullName, displayName, cpf, birthDate];
}

class SignupUseCase implements UseCase<UserEntity, SignupParams> {
  final AuthRepository repository;
  SignupUseCase(this.repository);

  @override
  Future<Either<Failure, UserEntity>> call(SignupParams params) {
    if (!params.email.contains('@')) {
      return Future.value(const Left(ValidationFailure('Email inválido.')));
    }
    if (params.password.length < 6) {
      return Future.value(const Left(ValidationFailure('Senha precisa ter ao menos 6 caracteres.')));
    }
    if (params.fullName.trim().length < 3) {
      return Future.value(const Left(ValidationFailure('Informe seu nome completo.')));
    }
    return repository.signup(
      email: params.email,
      password: params.password,
      fullName: params.fullName,
      displayName: params.displayName,
    );
  }
}
