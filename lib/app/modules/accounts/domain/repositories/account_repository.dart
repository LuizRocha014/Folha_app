import 'package:dartz/dartz.dart';
import '../../../../../core/errors/failures.dart';
import '../entities/account_entity.dart';

abstract class AccountRepository {
  Future<Either<Failure, List<AccountEntity>>> list();
  Future<Either<Failure, AccountEntity>> create({
    required String name,
    required String kind,
    String? institution,
    double initialBalance = 0,
  });
  Future<Either<Failure, void>> archive(String id);
}
