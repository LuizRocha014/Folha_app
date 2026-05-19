import 'package:dartz/dartz.dart';
import '../../../../../core/errors/exceptions.dart';
import '../../../../../core/errors/failures.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../datasources/transaction_remote_datasource.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  final TransactionRemoteDataSource remote;
  TransactionRepositoryImpl({required this.remote});

  @override
  Future<Either<Failure, List<TransactionEntity>>> list() async {
    try {
      final r = await remote.list();
      return Right(r);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, TransactionEntity>> add({
    required String description,
    required String place,
    required String category,
    required double value,
  }) async {
    try {
      final t = await remote.add(
        description: description,
        place: place,
        category: category,
        value: value,
      );
      return Right(t);
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, void>> remove(String id) async {
    try {
      await remote.remove(id);
      return const Right(null);
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }
}
