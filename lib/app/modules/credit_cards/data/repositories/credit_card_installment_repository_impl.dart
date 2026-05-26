import 'dart:async';
import 'dart:developer' as developer;
import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';
import '../../../../../core/errors/failures.dart';
import '../../../../../core/sync/outbox_repository.dart';
import '../../../../../core/sync/sync_manager.dart';
import '../../../../../core/sync/sync_status.dart';
import '../../domain/entities/credit_card_installment_entity.dart';
import '../../domain/repositories/credit_card_installment_repository.dart';
import '../datasources/credit_card_installment_local_datasource.dart';
import '../models/credit_card_installment_model.dart';

class CreditCardInstallmentRepositoryImpl
    implements CreditCardInstallmentRepository {
  CreditCardInstallmentRepositoryImpl({
    required this.local,
    required this.outbox,
    required this.syncManager,
    required this.currentUserId,
  });

  final CreditCardInstallmentLocalDataSource local;
  final OutboxRepository outbox;
  final SyncManager syncManager;
  final String Function() currentUserId;

  static const _uuid = Uuid();

  @override
  Future<Either<Failure, List<CreditCardInstallmentEntity>>> listByCard(
      String creditCardId) async {
    try {
      final items = await local.listByCard(creditCardId);
      return Right(items);
    } catch (e, st) {
      developer.log('listByCard', name: 'CreditCardInstallmentRepository', error: e, stackTrace: st);
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, CreditCardInstallmentEntity>> create({
    required String creditCardId,
    required String description,
    required int installmentTotal,
    required int installmentsPaid,
    required double installmentAmount,
    required DateTime startDate,
  }) async {
    try {
      final item = CreditCardInstallmentModel(
        id: _uuid.v4(),
        userId: currentUserId(),
        creditCardId: creditCardId,
        description: description,
        installmentTotal: installmentTotal,
        installmentsPaid: installmentsPaid,
        installmentAmount: installmentAmount,
        startDate: startDate,
        syncStatus: SyncStatus.pendingCreate,
      );
      await local.upsert(item);
      await outbox.enqueue(
        entity: 'credit_card_installments',
        entityId: item.id,
        operation: OutboxOperation.create,
        payload: item.toApiCreateJson(),
      );
      unawaited(syncManager.runPushOnly());
      return Right(item);
    } catch (e, st) {
      developer.log('create', name: 'CreditCardInstallmentRepository', error: e, stackTrace: st);
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> delete(String id) async {
    try {
      await local.delete(id);
      await outbox.enqueue(
        entity: 'credit_card_installments',
        entityId: id,
        operation: OutboxOperation.delete,
        payload: const {},
      );
      unawaited(syncManager.runPushOnly());
      return const Right(null);
    } catch (e, st) {
      developer.log('delete id=$id', name: 'CreditCardInstallmentRepository', error: e, stackTrace: st);
      return Left(UnknownFailure(e.toString()));
    }
  }
}
