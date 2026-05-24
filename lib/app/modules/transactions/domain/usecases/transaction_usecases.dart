import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../../core/errors/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../entities/transaction_entity.dart';
import '../repositories/transaction_repository.dart';

class ListTransactionsUseCase
    implements UseCase<List<TransactionEntity>, NoParams> {
  final TransactionRepository repository;
  ListTransactionsUseCase(this.repository);

  @override
  Future<Either<Failure, List<TransactionEntity>>> call(NoParams params) =>
      repository.list();
}

class AddTransactionParams extends Equatable {
  final String description;
  final String place;
  final String category;
  final double value;
  final String? creditCardId;
  final String? billId;
  final bool isExcludedFromReports;

  const AddTransactionParams({
    required this.description,
    required this.place,
    required this.category,
    required this.value,
    this.creditCardId,
    this.billId,
    this.isExcludedFromReports = false,
  });

  @override
  List<Object?> get props => [
        description,
        place,
        category,
        value,
        creditCardId,
        billId,
        isExcludedFromReports,
      ];
}

class AddTransactionUseCase
    implements UseCase<TransactionEntity, AddTransactionParams> {
  final TransactionRepository repository;
  AddTransactionUseCase(this.repository);

  @override
  Future<Either<Failure, TransactionEntity>> call(AddTransactionParams params) {
    if (params.description.trim().isEmpty) {
      return Future.value(const Left(ValidationFailure('Descrição obrigatória.')));
    }
    if (params.value == 0) {
      return Future.value(const Left(ValidationFailure('Valor deve ser diferente de zero.')));
    }
    return repository.add(
      description: params.description,
      place: params.place,
      category: params.category,
      value: params.value,
      creditCardId: params.creditCardId,
      billId: params.billId,
      isExcludedFromReports: params.isExcludedFromReports,
    );
  }
}

class DeleteTransactionUseCase implements UseCase<void, String> {
  final TransactionRepository repository;
  DeleteTransactionUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(String id) => repository.remove(id);
}
