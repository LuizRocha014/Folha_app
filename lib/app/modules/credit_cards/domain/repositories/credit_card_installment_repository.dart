import 'package:dartz/dartz.dart';
import '../../../../../core/errors/failures.dart';
import '../entities/credit_card_installment_entity.dart';

abstract class CreditCardInstallmentRepository {
  Future<Either<Failure, List<CreditCardInstallmentEntity>>> listByCard(String creditCardId);

  Future<Either<Failure, CreditCardInstallmentEntity>> create({
    required String creditCardId,
    required String description,
    required int installmentTotal,
    required int installmentsPaid,
    required double installmentAmount,
    required DateTime startDate,
  });

  Future<Either<Failure, void>> delete(String id);
}
