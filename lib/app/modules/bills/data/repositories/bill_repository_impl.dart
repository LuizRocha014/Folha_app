import 'dart:async';
import 'dart:developer' as developer;
import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';
import '../../../../../core/errors/failures.dart';
import '../../../../../core/sync/outbox_repository.dart';
import '../../../../../core/sync/sync_manager.dart';
import '../../../../../core/sync/sync_status.dart';
import '../../domain/entities/bill_entity.dart';
import '../../domain/repositories/bill_repository.dart';
import '../datasources/bill_local_datasource.dart';
import '../models/bill_model.dart';

class BillRepositoryImpl implements BillRepository {
  BillRepositoryImpl({
    required this.local,
    required this.outbox,
    required this.syncManager,
    required this.currentUserId,
  });

  final BillLocalDataSource local;
  final OutboxRepository outbox;
  final SyncManager syncManager;
  final String Function() currentUserId;

  static const _uuid = Uuid();

  @override
  Future<Either<Failure, List<BillEntity>>> list() async {
    try {
      final items = await local.list();
      return Right(items);
    } catch (e, st) {
      developer.log('list', name: 'BillRepository', error: e, stackTrace: st);
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, BillEntity>> create({
    required String description,
    required double amount,
    required DateTime? due,
    required bool isReceivable,
    String? categorySlug,
    String? accountId,
    String? notes,
    String? recurring,
    int? installmentCurrent,
    int? installmentTotal,
  }) async {
    try {
      final signed = isReceivable ? -amount.abs() : amount.abs();
      final bill = BillModel(
        id: _uuid.v4(),
        userId: currentUserId(),
        description: description,
        amount: signed,
        due: due,
        status: BillStatus.pending,
        recurring: recurring,
        categorySlug: categorySlug,
        accountId: accountId,
        notes: notes,
        installmentCurrent: installmentCurrent,
        installmentTotal: installmentTotal,
        syncStatus: SyncStatus.pendingCreate,
      );
      await local.upsert(bill);
      await outbox.enqueue(
        entity: 'bills',
        entityId: bill.id,
        operation: OutboxOperation.create,
        payload: bill.toApiCreateJson(),
      );
      unawaited(syncManager.runPushOnly());
      return Right(bill);
    } catch (e, st) {
      developer.log('create', name: 'BillRepository', error: e, stackTrace: st);
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, BillEntity>> updateStatus(String id, BillStatus status) async {
    try {
      final existing = await local.getById(id);
      if (existing == null) {
        return const Left(ValidationFailure('Conta não encontrada.'));
      }
      // Quando o usuário marca como pago/recebido, zera o saldo restante.
      final isSettling =
          status == BillStatus.paid || status == BillStatus.received;
      final updated = BillModel(
        id: existing.id,
        userId: existing.userId,
        description: existing.description,
        amount: existing.amount,
        due: existing.due,
        status: status,
        recurring: existing.recurring,
        categorySlug: existing.categorySlug,
        accountId: existing.accountId,
        notes: existing.notes,
        paidAmount: isSettling ? existing.amount.abs() : existing.paidAmount,
        installmentCurrent: existing.installmentCurrent,
        installmentTotal: existing.installmentTotal,
        syncStatus: existing.syncStatus == SyncStatus.pendingCreate
            ? SyncStatus.pendingCreate
            : SyncStatus.pendingUpdate,
      );
      await local.upsert(updated);
      await outbox.enqueue(
        entity: 'bills',
        entityId: id,
        operation: existing.syncStatus == SyncStatus.pendingCreate
            ? OutboxOperation.create
            : OutboxOperation.update,
        payload: {'status': status.id, 'paidAmount': updated.paidAmount},
      );
      unawaited(syncManager.runPushOnly());
      return Right(updated);
    } catch (e, st) {
      developer.log('updateStatus id=$id status=$status', name: 'BillRepository', error: e, stackTrace: st);
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, BillEntity>> applyPartialPayment({
    required String id,
    required double amountPaid,
  }) async {
    try {
      if (amountPaid <= 0) {
        return const Left(
          ValidationFailure('Informe um valor maior que zero.'),
        );
      }
      final existing = await local.getById(id);
      if (existing == null) {
        return const Left(ValidationFailure('Conta não encontrada.'));
      }
      if (existing.isSettled) {
        return const Left(
          ValidationFailure('Essa conta já está quitada.'),
        );
      }
      final total = existing.amount.abs();
      final newPaid =
          (existing.paidAmount + amountPaid).clamp(0.0, total).toDouble();
      final fullyPaid = newPaid >= total - 0.005; // tolerância de 0,5 centavo
      final nextStatus = fullyPaid
          ? (existing.amount >= 0 ? BillStatus.paid : BillStatus.received)
          : existing.status;
      final updated = BillModel(
        id: existing.id,
        userId: existing.userId,
        description: existing.description,
        amount: existing.amount,
        due: existing.due,
        status: nextStatus,
        recurring: existing.recurring,
        categorySlug: existing.categorySlug,
        accountId: existing.accountId,
        notes: existing.notes,
        paidAmount: newPaid,
        installmentCurrent: existing.installmentCurrent,
        installmentTotal: existing.installmentTotal,
        syncStatus: existing.syncStatus == SyncStatus.pendingCreate
            ? SyncStatus.pendingCreate
            : SyncStatus.pendingUpdate,
      );
      await local.upsert(updated);
      await outbox.enqueue(
        entity: 'bills',
        entityId: id,
        operation: existing.syncStatus == SyncStatus.pendingCreate
            ? OutboxOperation.create
            : OutboxOperation.update,
        payload: {
          'paidAmount': newPaid,
          if (fullyPaid) 'status': nextStatus.id,
        },
      );
      unawaited(syncManager.runPushOnly());
      return Right(updated);
    } catch (e, st) {
      developer.log('applyPartialPayment id=$id amount=$amountPaid', name: 'BillRepository', error: e, stackTrace: st);
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, BillEntity>> incrementAmount({
    required String id,
    required double delta,
  }) async {
    try {
      final existing = await local.getById(id);
      if (existing == null) {
        return const Left(ValidationFailure('Conta não encontrada.'));
      }
      // Mantém o sinal (a pagar = positivo, a receber = negativo).
      final sign = existing.amount >= 0 ? 1 : -1;
      final newAmount = existing.amount + (sign * delta.abs());
      final updated = BillModel(
        id: existing.id,
        userId: existing.userId,
        description: existing.description,
        amount: newAmount,
        due: existing.due,
        status: existing.status,
        recurring: existing.recurring,
        categorySlug: existing.categorySlug,
        accountId: existing.accountId,
        notes: existing.notes,
        paidAmount: existing.paidAmount,
        installmentCurrent: existing.installmentCurrent,
        installmentTotal: existing.installmentTotal,
        syncStatus: existing.syncStatus == SyncStatus.pendingCreate
            ? SyncStatus.pendingCreate
            : SyncStatus.pendingUpdate,
      );
      await local.upsert(updated);
      await outbox.enqueue(
        entity: 'bills',
        entityId: id,
        operation: existing.syncStatus == SyncStatus.pendingCreate
            ? OutboxOperation.create
            : OutboxOperation.update,
        payload: {'amount': newAmount.abs()},
      );
      unawaited(syncManager.runPushOnly());
      return Right(updated);
    } catch (e, st) {
      developer.log('incrementAmount id=$id delta=$delta', name: 'BillRepository', error: e, stackTrace: st);
      return Left(UnknownFailure(e.toString()));
    }
  }
}
