import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../../core/errors/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../entities/bill_entity.dart';
import '../repositories/bill_repository.dart';

class ListBillsUseCase implements UseCase<List<BillEntity>, NoParams> {
  final BillRepository repository;
  ListBillsUseCase(this.repository);

  @override
  Future<Either<Failure, List<BillEntity>>> call(NoParams params) =>
      repository.list();
}

class UpdateBillStatusParams extends Equatable {
  final String id;
  final BillStatus status;
  const UpdateBillStatusParams({required this.id, required this.status});

  @override
  List<Object?> get props => [id, status];
}

class UpdateBillStatusUseCase
    implements UseCase<BillEntity, UpdateBillStatusParams> {
  final BillRepository repository;
  UpdateBillStatusUseCase(this.repository);

  @override
  Future<Either<Failure, BillEntity>> call(UpdateBillStatusParams params) =>
      repository.updateStatus(params.id, params.status);
}
