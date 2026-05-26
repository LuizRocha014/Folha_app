import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../../core/errors/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class VerifyEmailParams extends Equatable {
  final String email;
  final String code;
  const VerifyEmailParams({required this.email, required this.code});

  @override
  List<Object?> get props => [email, code];
}

/// Confirma o código de verificação; em caso de sucesso já autentica a sessão.
class VerifyEmailUseCase implements UseCase<UserEntity, VerifyEmailParams> {
  final AuthRepository repository;
  VerifyEmailUseCase(this.repository);

  @override
  Future<Either<Failure, UserEntity>> call(VerifyEmailParams params) {
    if (params.code.trim().length < 4) {
      return Future.value(const Left(ValidationFailure('Digite o código completo.')));
    }
    return repository.verifyEmail(email: params.email, code: params.code.trim());
  }
}
