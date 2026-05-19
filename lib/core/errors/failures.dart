import 'package:equatable/equatable.dart';

/// Falhas (camada de domínio) — retornadas dentro de `Either<Failure, T>`.
abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Erro no servidor.']);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Sem conexão com a internet.']);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Erro ao acessar cache local.']);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Falha na autenticação.']);
}

class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'Algo deu errado.']);
}
