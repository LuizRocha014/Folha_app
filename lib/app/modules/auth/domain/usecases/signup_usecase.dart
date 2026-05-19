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
  final String cpf;
  final DateTime birthDate;

  const SignupParams({
    required this.email,
    required this.password,
    required this.fullName,
    required this.cpf,
    required this.birthDate,
  });

  @override
  List<Object?> get props => [email, password, fullName, cpf, birthDate];
}

class SignupUseCase implements UseCase<UserEntity, SignupParams> {
  final AuthRepository repository;
  SignupUseCase(this.repository);

  @override
  Future<Either<Failure, UserEntity>> call(SignupParams params) {
    return repository.signup(
      email: params.email,
      password: params.password,
      fullName: params.fullName,
      cpf: params.cpf,
      birthDate: params.birthDate,
    );
  }
}
