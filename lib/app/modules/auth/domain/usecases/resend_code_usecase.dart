import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../../core/errors/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../repositories/auth_repository.dart';

class ResendCodeParams extends Equatable {
  final String email;
  const ResendCodeParams({required this.email});

  @override
  List<Object?> get props => [email];
}

/// Pede um novo código de verificação para o e-mail informado.
class ResendCodeUseCase implements UseCase<void, ResendCodeParams> {
  final AuthRepository repository;
  ResendCodeUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(ResendCodeParams params) {
    return repository.resendCode(email: params.email);
  }
}
