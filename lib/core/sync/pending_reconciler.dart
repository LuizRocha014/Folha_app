import 'dart:developer' as developer;
import '../../app/modules/credit_cards/data/models/credit_card_installment_model.dart';
import '../../app/modules/credit_cards/data/models/credit_card_model.dart';
import '../../app/modules/goals/data/models/goal_model.dart';
import '../database/local_database.dart';
import 'outbox_repository.dart';
import 'sync_status.dart';

/// Reenfileira no outbox registros locais que ficaram pendentes mas SEM uma
/// entrada viva no outbox — tipicamente "órfãos" deixados por versões antigas
/// (ex.: o antigo `CreditCardSyncer` read-only marcava o outbox como processado
/// sem nunca enviar o cartão ao servidor). Sem isso, um cartão criado naquela
/// época nunca chega ao backend e qualquer transação sobre ele estoura o FK
/// `FK_FOLHA_Tx_card`.
///
/// Roda no bootstrap, antes do sync. É idempotente: só reenfileira quando não
/// existe entrada pendente para aquele id, e assim que o registro sincroniza
/// (vira `synced`) ele para de ser considerado.
///
/// Ordem importa por causa das FKs no servidor — por isso reconciliamos
/// cartões antes de parcelamentos antes de transações.
class PendingReconciler {
  PendingReconciler({required this.db, required this.outbox});

  final LocalDatabase db;
  final OutboxRepository outbox;

  Future<void> run() async {
    final userId = db.userId;
    if (userId.isEmpty) return;

    try {
      await _reconcileCreditCards(userId);
      await _reconcileInstallments(userId);
      await _reconcileTransactions(userId);
      await _reconcileGoals(userId);
      await _reconcileNotifications(userId);
    } catch (e, st) {
      developer.log('run', name: 'PendingReconciler', error: e, stackTrace: st);
    }
  }

  Future<bool> _hasLiveOutbox(String entity, String id) async {
    final rows = await db.raw.query(
      '_outbox',
      where: 'entity = ? AND entity_id = ? AND processed_at IS NULL',
      whereArgs: [entity, id],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  String _operationFor(String syncStatus) {
    switch (syncStatus) {
      case SyncStatus.pendingDelete:
        return OutboxOperation.delete;
      case SyncStatus.pendingUpdate:
        return OutboxOperation.update;
      default:
        return OutboxOperation.create;
    }
  }

  Future<void> _reconcileCreditCards(String userId) async {
    final rows = await db.raw.query(
      'credit_cards',
      where: "user_id = ? AND _sync_status LIKE 'pending_%'",
      whereArgs: [userId],
    );
    for (final row in rows) {
      final id = row['id'] as String;
      if (await _hasLiveOutbox('credit_cards', id)) continue;

      final status = row['_sync_status'] as String;
      final op = _operationFor(status);
      final model = CreditCardModel.fromRow(row);
      await outbox.enqueue(
        entity: 'credit_cards',
        entityId: id,
        operation: op,
        payload: op == OutboxOperation.update
            ? model.toApiUpdateJson()
            : (op == OutboxOperation.delete ? const {} : model.toApiCreateJson()),
      );
      developer.log('reenfileirado credit_cards/$id ($op)', name: 'PendingReconciler');
    }
  }

  Future<void> _reconcileInstallments(String userId) async {
    final rows = await db.raw.query(
      'credit_card_installments',
      where: "user_id = ? AND _sync_status LIKE 'pending_%'",
      whereArgs: [userId],
    );
    for (final row in rows) {
      final id = row['id'] as String;
      if (await _hasLiveOutbox('credit_card_installments', id)) continue;

      final status = row['_sync_status'] as String;
      final op = _operationFor(status);
      final model = CreditCardInstallmentModel.fromRow(row);
      await outbox.enqueue(
        entity: 'credit_card_installments',
        entityId: id,
        operation: op,
        payload: op == OutboxOperation.update
            ? model.toApiUpdateJson()
            : (op == OutboxOperation.delete ? const {} : model.toApiCreateJson()),
      );
      developer.log('reenfileirado credit_card_installments/$id ($op)', name: 'PendingReconciler');
    }
  }

  Future<void> _reconcileGoals(String userId) async {
    final rows = await db.raw.query(
      'goals',
      where: "user_id = ? AND _sync_status LIKE 'pending_%'",
      whereArgs: [userId],
    );
    for (final row in rows) {
      final id = row['id'] as String;
      if (await _hasLiveOutbox('goals', id)) continue;

      final status = row['_sync_status'] as String;
      final op = _operationFor(status);
      // Metas só têm create/delete pela UI; usamos o payload de create.
      await outbox.enqueue(
        entity: 'goals',
        entityId: id,
        operation: op,
        payload: op == OutboxOperation.delete
            ? const {}
            : GoalModel.fromRow(row).toApiCreateJson(),
      );
      developer.log('reenfileirado goals/$id ($op)', name: 'PendingReconciler');
    }
  }

  Future<void> _reconcileNotifications(String userId) async {
    final rows = await db.raw.query(
      'notifications',
      where: "user_id = ? AND _sync_status LIKE 'pending_%'",
      whereArgs: [userId],
    );
    for (final row in rows) {
      final id = row['id'] as String;
      if (await _hasLiveOutbox('notifications', id)) continue;

      // Única mutação local é marcar como lida.
      await outbox.enqueue(
        entity: 'notifications',
        entityId: id,
        operation: OutboxOperation.update,
        payload: const {'isRead': true},
      );
      developer.log('reenfileirado notifications/$id (update)', name: 'PendingReconciler');
    }
  }

  Future<void> _reconcileTransactions(String userId) async {
    final rows = await db.raw.query(
      'transactions',
      where: "user_id = ? AND _sync_status LIKE 'pending_%'",
      whereArgs: [userId],
    );
    for (final row in rows) {
      final id = row['id'] as String;
      if (await _hasLiveOutbox('transactions', id)) continue;

      final status = row['_sync_status'] as String;
      final op = _operationFor(status);
      // O TransactionSyncer reconstrói o payload a partir da row local; aqui o
      // conteúdo é só informativo.
      await outbox.enqueue(
        entity: 'transactions',
        entityId: id,
        operation: op,
        payload: const {'reconciled': true},
      );
      developer.log('reenfileirado transactions/$id ($op)', name: 'PendingReconciler');
    }
  }
}
