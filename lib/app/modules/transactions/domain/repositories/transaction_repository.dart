import 'package:dartz/dartz.dart';
import '../../../../../core/errors/failures.dart';
import '../entities/transaction_entity.dart';

abstract class TransactionRepository {
  Future<Either<Failure, List<TransactionEntity>>> list();

  Future<Either<Failure, TransactionEntity>> add({
    required String description,
    required String place,
    required String category,
    required double value,
  });

  Future<Either<Failure, void>> remove(String id);
}
