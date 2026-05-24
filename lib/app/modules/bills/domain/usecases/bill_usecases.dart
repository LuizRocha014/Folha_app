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

class CreateBillParams extends Equatable {
  final String description;
  final double amount;
  final DateTime? due;
  final bool isReceivable;
  final String? categorySlug;
  final String? accountId;
  final String? notes;
  final String? recurring;
  final int? installmentCurrent;
  final int? installmentTotal;

  const CreateBillParams({
    required this.description,
    required this.amount,
    required this.due,
    required this.isReceivable,
    this.categorySlug,
    this.accountId,
    this.notes,
    this.recurring,
    this.installmentCurrent,
    this.installmentTotal,
  });

  @override
  List<Object?> get props => [
        description, amount, due, isReceivable, categorySlug, accountId, notes,
        recurring, installmentCurrent, installmentTotal,
      ];
}

class CreateBillUseCase implements UseCase<BillEntity, CreateBillParams> {
  final BillRepository repository;
  CreateBillUseCase(this.repository);

  @override
  Future<Either<Failure, BillEntity>> call(CreateBillParams p) {
    if (p.description.trim().isEmpty) {
      return Future.value(const Left(ValidationFailure('Descrição obrigatória.')));
    }
    if (p.amount <= 0) {
      return Future.value(const Left(ValidationFailure('Informe um valor maior que zero.')));
    }
    if (p.installmentTotal != null) {
      if (p.installmentTotal! < 1) {
        return Future.value(
          const Left(ValidationFailure('Total de parcelas inválido.')),
        );
      }
      final current = p.installmentCurrent ?? 1;
      if (current < 1 || current > p.installmentTotal!) {
        return Future.value(
          const Left(ValidationFailure('Parcela atual fora do intervalo.')),
        );
      }
    }
    return repository.create(
      description: p.description.trim(),
      amount: p.amount,
      due: p.due,
      isReceivable: p.isReceivable,
      categorySlug: p.categorySlug,
      accountId: p.accountId,
      notes: p.notes,
      recurring: p.recurring,
      installmentCurrent: p.installmentCurrent,
      installmentTotal: p.installmentTotal,
    );
  }
}

class PayPartialParams extends Equatable {
  final String billId;
  final double amount;

  const PayPartialParams({required this.billId, required this.amount});

  @override
  List<Object?> get props => [billId, amount];
}

class PayPartialUseCase implements UseCase<BillEntity, PayPartialParams> {
  final BillRepository repository;
  PayPartialUseCase(this.repository);

  @override
  Future<Either<Failure, BillEntity>> call(PayPartialParams p) {
    if (p.amount <= 0) {
      return Future.value(
        const Left(ValidationFailure('Informe um valor maior que zero.')),
      );
    }
    return repository.applyPartialPayment(
      id: p.billId,
      amountPaid: p.amount,
    );
  }
}
