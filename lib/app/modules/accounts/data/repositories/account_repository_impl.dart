import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';
import '../../../../../core/errors/failures.dart';
import '../../../../../core/sync/outbox_repository.dart';
import '../../../../../core/sync/sync_manager.dart';
import '../../../../../core/sync/sync_status.dart';
import '../../domain/entities/account_entity.dart';
import '../../domain/repositories/account_repository.dart';
import '../datasources/account_local_datasource.dart';
import '../models/account_model.dart';

class AccountRepositoryImpl implements AccountRepository {
  AccountRepositoryImpl({
    required this.local,
    required this.outbox,
    required this.syncManager,
    required this.currentUserId,
  });

  final AccountLocalDataSource local;
  final OutboxRepository outbox;
  final SyncManager syncManager;
  final String Function() currentUserId;

  static const _uuid = Uuid();

  @override
  Future<Either<Failure, List<AccountEntity>>> list() async {
    try {
      return Right(await local.list());
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, AccountEntity>> create({
    required String name,
    required String kind,
    String? institution,
    double initialBalance = 0,
  }) async {
    try {
      final acc = AccountModel(
        id: _uuid.v4(),
        userId: currentUserId(),
        name: name,
        kind: kind,
        institution: institution,
        initialBalance: initialBalance,
        syncStatus: SyncStatus.pendingCreate,
      );
      await local.upsert(acc);
      await outbox.enqueue(
        entity: 'accounts',
        entityId: acc.id,
        operation: OutboxOperation.create,
        payload: acc.toApiCreateJson(),
      );
      unawaited(syncManager.runPushOnly());
      return Right(acc);
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> archive(String id) async {
    try {
      final existing = await local.getById(id);
      if (existing == null) return const Right(null);
      if (existing.syncStatus == SyncStatus.pendingCreate) {
        await local.delete(id);
        return const Right(null);
      }
      await local.upsert(
        AccountModel(
          id: existing.id,
          userId: existing.userId,
          name: existing.name,
          kind: existing.kind,
          institution: existing.institution,
          icon: existing.icon,
          colorHex: existing.colorHex,
          initialBalance: existing.initialBalance,
          currencyCode: existing.currencyCode,
          isArchived: true,
          includeInTotal: existing.includeInTotal,
          sortOrder: existing.sortOrder,
          syncStatus: SyncStatus.pendingDelete,
        ),
      );
      await outbox.enqueue(
        entity: 'accounts',
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
