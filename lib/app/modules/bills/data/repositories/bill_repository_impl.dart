import 'package:dartz/dartz.dart';
import '../../../../../core/errors/failures.dart';
import '../../domain/entities/bill_entity.dart';
import '../../domain/repositories/bill_repository.dart';
import '../datasources/bill_remote_datasource.dart';

class BillRepositoryImpl implements BillRepository {
  final BillRemoteDataSource remote;
  BillRepositoryImpl({required this.remote});

  @override
  Future<Either<Failure, List<BillEntity>>> list() async {
    try {
      final r = await remote.list();
      return Right(r);
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, BillEntity>> updateStatus(
    String id,
    BillStatus status,
  ) async {
    try {
      final r = await remote.updateStatus(id, status);
      return Right(r);
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }
}
