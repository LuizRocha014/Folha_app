import 'dart:async';
import 'dart:developer' as developer;
import 'package:uuid/uuid.dart';
import '../../../../../core/database/category_lookup.dart';
import '../../../../../core/database/local_database.dart';
import '../../../../../core/sync/outbox_repository.dart';
import '../../../../../core/sync/sync_manager.dart';
import '../../../../../core/sync/sync_status.dart';
import '../../../transactions/data/datasources/transaction_local_datasource.dart';
import '../../../transactions/data/models/transaction_model.dart';
import 'card_invoice.dart' show kInstallmentTxNote;

/// Materializa as parcelas fixas dos cartões em transações reais conforme o
/// tempo passa ("quando o cartão vira").
///
/// Para cada parcelamento, calcula quantas parcelas já venceram a partir de
/// `start_date` (parcela P+1) e do dia de fechamento do cartão, e gera uma
/// transação por parcela vencida que ainda não tenha sido gerada.
///
/// Idempotência: o id de cada transação é derivado deterministicamente de
/// `(planId, número da parcela)` via UUID v5. Rodar de novo não duplica nada —
/// só cria o que faltar. Seguro chamar a cada abertura/sync.
class InstallmentMaterializer {
  InstallmentMaterializer({
    required this.db,
    required this.txLocal,
    required this.outbox,
    required this.categories,
    required this.syncManager,
  });

  final LocalDatabase db;
  final TransactionLocalDataSource txLocal;
  final OutboxRepository outbox;
  final CategoryLookup categories;
  final SyncManager syncManager;

  static const _uuid = Uuid();
  // Namespace fixo (o namespace URL padrão de UUID) para gerar ids v5 estáveis.
  static const _namespace = '6ba7b811-9dad-11d1-80b4-00c04fd430c8';

  Future<void> run() async {
    try {
      final userId = db.userId;
      if (userId.isEmpty) return;

      final cardRows = await db.raw.query(
        'credit_cards',
        where: 'user_id = ? AND is_archived = 0',
        whereArgs: [userId],
      );
      final closingByCard = <String, int>{
        for (final c in cardRows)
          c['id'] as String: ((c['closing_day'] as num?) ?? 1).toInt(),
      };

      final planRows = await db.raw.query(
        'credit_card_installments',
        where: 'user_id = ?',
        whereArgs: [userId],
      );
      if (planRows.isEmpty) return;

      final now = DateTime.now();
      var createdAny = false;

      for (final plan in planRows) {
        final cardId = plan['credit_card_id'] as String;
        final closingDay = closingByCard[cardId];
        if (closingDay == null) continue; // cartão arquivado/inexistente — ignora

        final total = ((plan['installment_total'] as num?) ?? 1).toInt();
        final paidAtStart = ((plan['installments_paid'] as num?) ?? 0).toInt();
        final amount = ((plan['installment_amount'] as num?) ?? 0).toDouble();
        final description = (plan['description'] as String?) ?? 'Parcelamento';
        final planId = plan['id'] as String;
        final start = DateTime.parse(plan['start_date'] as String);

        if (amount <= 0 || total < 1) continue;

        final monthsSinceStart =
            (now.year - start.year) * 12 + (now.month - start.month);
        if (monthsSinceStart < 0) continue; // ainda não começou

        final currentMonthClosed = now.day >= closingDay;
        final dueCount = monthsSinceStart + (currentMonthClosed ? 1 : 0);
        if (dueCount <= 0) continue;

        final lastNumber =
            (paidAtStart + dueCount) > total ? total : (paidAtStart + dueCount);

        for (var n = paidAtStart + 1; n <= lastNumber; n++) {
          final txId = _uuid.v5(_namespace, '$planId:$n');
          final existing = await txLocal.getById(txId);
          if (existing != null) continue; // já materializada

          final monthOffset = n - (paidAtStart + 1);
          final occMonth = DateTime(start.year, start.month + monthOffset, 1);
          final occDay = closingDay > _daysInMonth(occMonth.year, occMonth.month)
              ? _daysInMonth(occMonth.year, occMonth.month)
              : closingDay;
          final occurredAt = DateTime(occMonth.year, occMonth.month, occDay);

          final model = TransactionModel(
            id: txId,
            userId: userId,
            creditCardId: cardId,
            description: '$description ($n/$total)',
            place: '',
            category: 'other',
            value: -amount, // saída
            when: occurredAt,
            kind: 'expense',
            note: kInstallmentTxNote,
            // A fonte de verdade do que sai da conta é a Fatura (conta a pagar)
            // do cartão — então a parcela não entra em relatórios/saldo, igual a
            // uma compra no cartão. Evita contar o mesmo dinheiro duas vezes.
            isExcludedFromReports: true,
            syncStatus: SyncStatus.pendingCreate,
          );

          await txLocal.upsert(model);
          final categoryId = await categories.slugToId('other') ?? 8;
          await outbox.enqueue(
            entity: 'transactions',
            entityId: txId,
            operation: OutboxOperation.create,
            payload: model.toApiCreateJson(categoryId: categoryId),
          );
          createdAny = true;
        }
      }

      if (createdAny) {
        unawaited(syncManager.runPushOnly());
      }
    } catch (e, st) {
      developer.log('run', name: 'InstallmentMaterializer', error: e, stackTrace: st);
    }
  }

  static int _daysInMonth(int year, int month) =>
      DateTime(year, month + 1, 0).day;
}
