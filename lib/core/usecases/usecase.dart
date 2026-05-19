import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../errors/failures.dart';

/// Contrato genérico de UseCase (Clean Arch).
/// Domain → `Either<Failure, Output>`; Input pode ser NoParams ou um objeto.
abstract class UseCase<Output, Input> {
  Future<Either<Failure, Output>> call(Input params);
}

class NoParams extends Equatable {
  const NoParams();
  @override
  List<Object?> get props => [];
}
