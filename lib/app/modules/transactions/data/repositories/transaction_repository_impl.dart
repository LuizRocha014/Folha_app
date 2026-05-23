import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';
import '../../../../../core/errors/exceptions.dart';
import '../../../../../core/errors/failures.dart';
import '../../../../../core/sync/outbox_repository.dart';
import '../../../../../core/sync/sync_manager.dart';
import '../../../../../core/sync/sync_status.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../datasources/transaction_local_datasource.dart';
import '../datasources/transaction_remote_datasource.dart';
import '../models/transaction_model.dart';

/// Repository offline-first.
///
/// Leituras: sempre do banco local (rápido, funciona offline).
/// Escritas: gravam local com `_sync_status` pendente + enfileiram no outbox.
/// O `SyncManager` drena o outbox quando volta conexão.
class TransactionRepositoryImpl implements TransactionRepository {
  TransactionRepositoryImpl({
    required this.local,
    required this.remote,
    required this.outbox,
    required this.syncManager,
    required this.currentUserId,
  });

  final TransactionLocalDataSource local;
  final TransactionRemoteDataSource remote;
  final OutboxRepository outbox;
  final SyncManager syncManager;
  final String Function() currentUserId;

  static const _uuid = Uuid();

  @override
  Future<Either<Failure, List<TransactionEntity>>> list() async {
    try {
      final items = await local.list();
      return Right(items);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, TransactionEntity>> add({
    required String description,
    required String place,
    required String category,
    required double value,
    String? billId,
    bool isExcludedFromReports = false,
    String? kindOverride,
  }) async {
    try {
      final tx = TransactionModel(
        id: _uuid.v4(),
        userId: currentUserId(),
        description: description,
        place: place,
        category: category,
        value: value,
        when: DateTime.now(),
        kind: kindOverride ?? (value >= 0 ? 'income' : 'expense'),
        billId: billId,
        isExcludedFromReports: isExcludedFromReports,
        syncStatus: SyncStatus.pendingCreate,
      );
      await local.upsert(tx);
      await outbox.enqueue(
        entity: 'transactions',
        entityId: tx.id,
        operation: OutboxOperation.create,
        payload: {
          'description': description,
          'place': place,
          'category_slug': category,
          'value': value,
          'bill_id': ?billId,
          if (isExcludedFromReports) 'excluded': true,
        },
      );
      unawaited(syncManager.runPushOnly());
      return Right(tx);
    } on NetworkException {
      return const Left(NetworkFailure());
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> remove(String id) async {
    try {
      final existing = await local.getById(id);
      if (existing == null) return const Right(null);

      // Se a transação ainda não foi sincronizada, podemos só apagar local.
      if (existing.syncStatus == SyncStatus.pendingCreate) {
        await local.delete(id);
        return const Right(null);
      }

      await local.markPendingDelete(id);
      await outbox.enqueue(
        entity: 'transactions',
        entityId: id,
        operation: OutboxOperation.delete,
        payload: const {},
      );
      unawaited(syncManager.runPushOnly());
      return const Right(null);
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
}
