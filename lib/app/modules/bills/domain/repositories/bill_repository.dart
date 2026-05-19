import 'package:dartz/dartz.dart';
import '../../../../../core/errors/failures.dart';
import '../entities/bill_entity.dart';

abstract class BillRepository {
  Future<Either<Failure, List<BillEntity>>> list();
  Future<Either<Failure, BillEntity>> updateStatus(
    String id,
    BillStatus status,
  );
}
