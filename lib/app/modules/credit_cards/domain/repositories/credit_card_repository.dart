import 'package:dartz/dartz.dart';
import '../../../../../core/errors/failures.dart';
import '../entities/credit_card_entity.dart';

abstract class CreditCardRepository {
  Future<Either<Failure, List<CreditCardEntity>>> list();
  Future<Either<Failure, CreditCardEntity>> create({
    required String name,
    required String brand,
    required double creditLimit,
    required int closingDay,
    required int dueDay,
    String? lastFour,
    String? accountId,
  });
  Future<Either<Failure, void>> archive(String id);
}
