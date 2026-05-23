import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';
import '../../../../../core/errors/failures.dart';
import '../../../../../core/sync/outbox_repository.dart';
import '../../../../../core/sync/sync_manager.dart';
import '../../../../../core/sync/sync_status.dart';
import '../../domain/entities/credit_card_entity.dart';
import '../../domain/repositories/credit_card_repository.dart';
import '../datasources/credit_card_local_datasource.dart';
import '../models/credit_card_model.dart';

class CreditCardRepositoryImpl implements CreditCardRepository {
  CreditCardRepositoryImpl({
    required this.local,
    required this.outbox,
    required this.syncManager,
    required this.currentUserId,
  });

  final CreditCardLocalDataSource local;
  final OutboxRepository outbox;
  final SyncManager syncManager;
  final String Function() currentUserId;

  static const _uuid = Uuid();

  @override
  Future<Either<Failure, List<CreditCardEntity>>> list() async {
    try {
      final items = await local.listActive();
      return Right(items);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, CreditCardEntity>> create({
    required String name,
    required String brand,
    required double creditLimit,
    required int closingDay,
    required int dueDay,
    String? lastFour,
    String? accountId,
  }) async {
    try {
      final card = CreditCardModel(
        id: _uuid.v4(),
        userId: currentUserId(),
        accountId: accountId,
        name: name,
        brand: brand,
        lastFour: lastFour,
        creditLimit: creditLimit,
        closingDay: closingDay,
        dueDay: dueDay,
        syncStatus: SyncStatus.pendingCreate,
      );
      await local.upsert(card);
      await outbox.enqueue(
        entity: 'credit_cards',
        entityId: card.id,
        operation: OutboxOperation.create,
        payload: card.toApiCreateJson(),
      );
      unawaited(syncManager.runPushOnly());
      return Right(card);
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> archive(String id) async {
    try {
      await local.archive(id);
      await outbox.enqueue(
        entity: 'credit_cards',
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
