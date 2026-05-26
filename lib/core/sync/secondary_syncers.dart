import 'package:sqflite_sqlcipher/sqflite.dart';
import '../database/local_database.dart';
import '../errors/exceptions.dart';
import '../network/base_remote_service.dart';
import 'entity_syncer.dart';
import 'outbox_repository.dart';

/// Syncers read-only de entidades secundárias (sem UI dedicada por ora):
/// CreditCards, Budgets, Goals, Recurrences, Notifications.
/// Cada um faz pull/upsert no banco local — o CRUD via UI será adicionado
/// conforme a feature aparece.

/// Base para reduzir boilerplate dos syncers simples.
///
/// Reaproveita `BaseRemoteService` (mesma camada de HTTP/refresh dos demais
/// datasources) — basta dizer o `endpoint` e como mapear o JSON para a row.
abstract class _SimplePullSyncer extends BaseRemoteService
    implements EntitySyncer {
  _SimplePullSyncer({required super.http, required this.db});

  final LocalDatabase db;

  String get endpoint;
  String get table;

  /// Mapeia campos do JSON da API para a row SQLite.
  /// `_local_updated_at` e `_sync_status='synced'` são preenchidos automaticamente.
  Map<String, dynamic> mapApiToRow(Map<String, dynamic> json);

  @override
  Future<void> pullAll() async {
    try {
      final list = await getList(endpoint);
      await db.raw.transaction((txn) async {
        await txn.delete(table, where: '_sync_status = ?', whereArgs: ['synced']);
        for (final json in list) {
          final row = mapApiToRow(json);
          row['_sync_status'] = 'synced';
          row['_local_updated_at'] = DateTime.now().millisecondsSinceEpoch;
          row['_server_updated_at'] = DateTime.now().millisecondsSinceEpoch;
          await txn.insert(table, row, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      });
    } on NetworkException {
      rethrow;
    } on Exception {
      // Read-only — não há nada para reconciliar quando o servidor falha.
    }
  }

  @override
  Future<void> pushEntry(OutboxEntry entry) async {
    // Read-only sync — nada a push.
  }
}

class BudgetSyncer extends _SimplePullSyncer {
  BudgetSyncer({required super.http, required super.db});

  @override
  String get entityName => 'budgets';
  @override
  int get order => 70;
  @override
  String get endpoint => '/api/budgets';
  @override
  String get table => 'budgets';

  @override
  Map<String, dynamic> mapApiToRow(Map<String, dynamic> j) {
    final now = DateTime.now().toUtc().toIso8601String();
    return {
      'id': j['id'],
      'user_id': j['userId'],
      // Salvamos slug 'other' como placeholder — quando UI usar, fazer lookup.
      'category_slug': 'other',
      'reference_month': j['referenceMonth'],
      'amount_limit': (j['amountLimit'] as num?)?.toDouble() ?? 0,
      'rollover': (j['rollover'] == true) ? 1 : 0,
      'alert_threshold': j['alertThreshold'] ?? 80,
      'created_at': now,
      'updated_at': now,
    };
  }
}

class GoalSyncer extends _SimplePullSyncer {
  GoalSyncer({required super.http, required super.db});

  @override
  String get entityName => 'goals';
  @override
  int get order => 80;
  @override
  String get endpoint => '/api/goals';
  @override
  String get table => 'goals';

  @override
  Map<String, dynamic> mapApiToRow(Map<String, dynamic> j) {
    final now = DateTime.now().toUtc().toIso8601String();
    return {
      'id': j['id'],
      'user_id': j['userId'],
      'account_id': j['accountId'],
      'title': j['title'] ?? '',
      'description': j['description'],
      'target_amount': (j['targetAmount'] as num?)?.toDouble() ?? 0,
      'current_amount': (j['currentAmount'] as num?)?.toDouble() ?? 0,
      'target_date': j['targetDate'],
      'icon': j['icon'],
      'color_hex': j['colorHex'],
      'is_completed': (j['isCompleted'] == true) ? 1 : 0,
      'completed_at': j['completedAt'],
      'is_archived': (j['isArchived'] == true) ? 1 : 0,
      'monthly_yield_percent': (j['monthlyYieldPercent'] as num?)?.toDouble(),
      'is_cdb': (j['isCdb'] == true) ? 1 : 0,
      'created_at': now,
      'updated_at': now,
    };
  }

  // Push real (a UI cria metas). O payload já vem pronto do controller; o
  // backend aceita o id do cliente, então o id local continua válido.
  @override
  Future<void> pushEntry(OutboxEntry entry) async {
    switch (entry.operation) {
      case 'create':
        await postMap(endpoint, body: entry.payload);
        await _markSynced(entry.entityId);
        break;
      case 'update':
        await putMap('$endpoint/${entry.entityId}', body: entry.payload);
        await _markSynced(entry.entityId);
        break;
      case 'delete':
        await deleteVoid('$endpoint/${entry.entityId}');
        await db.raw.delete(table, where: 'id = ?', whereArgs: [entry.entityId]);
        break;
    }
  }

  Future<void> _markSynced(String id) async {
    await db.raw.update(
      table,
      {
        '_sync_status': 'synced',
        '_server_updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

class RecurrenceSyncer extends _SimplePullSyncer {
  RecurrenceSyncer({required super.http, required super.db});

  @override
  String get entityName => 'recurrences';
  @override
  int get order => 40;
  @override
  String get endpoint => '/api/recurrences';
  @override
  String get table => 'recurrences';

  @override
  Map<String, dynamic> mapApiToRow(Map<String, dynamic> j) {
    final now = DateTime.now().toUtc().toIso8601String();
    return {
      'id': j['id'],
      'user_id': j['userId'],
      'frequency': j['frequency'] ?? 'monthly',
      'every_n': j['everyN'] ?? 1,
      'day_of_month': j['dayOfMonth'],
      'day_of_week': j['dayOfWeek'],
      'month_of_year': j['monthOfYear'],
      'start_date': j['startDate'],
      'end_date': j['endDate'],
      'max_occurrences': j['maxOccurrences'],
      'last_generated_at': j['lastGeneratedAt'],
      'created_at': now,
      'updated_at': now,
    };
  }
}

class NotificationSyncer extends _SimplePullSyncer {
  NotificationSyncer({required super.http, required super.db});

  @override
  String get entityName => 'notifications';
  @override
  int get order => 90;
  @override
  String get endpoint => '/api/notifications';
  @override
  String get table => 'notifications';

  @override
  Map<String, dynamic> mapApiToRow(Map<String, dynamic> j) {
    final now = DateTime.now().toUtc().toIso8601String();
    return {
      'id': j['id'],
      'user_id': j['userId'],
      'kind': j['kind'] ?? 'system',
      'title': j['title'] ?? '',
      'body': j['body'],
      'related_kind': j['relatedKind'],
      'related_id': j['relatedId'],
      'scheduled_for': j['scheduledFor'],
      'is_read': (j['isRead'] == true) ? 1 : 0,
      'read_at': j['readAt'],
      'created_at': now,
      'updated_at': now,
    };
  }

  // Push real: a única mutação local hoje é marcar como lida.
  @override
  Future<void> pushEntry(OutboxEntry entry) async {
    switch (entry.operation) {
      case 'create':
      case 'update':
        await postVoid('$endpoint/${entry.entityId}/read');
        await db.raw.update(
          table,
          {
            '_sync_status': 'synced',
            '_server_updated_at': DateTime.now().millisecondsSinceEpoch,
          },
          where: 'id = ?',
          whereArgs: [entry.entityId],
        );
        break;
      case 'delete':
        await deleteVoid('$endpoint/${entry.entityId}');
        await db.raw.delete(table, where: 'id = ?', whereArgs: [entry.entityId]);
        break;
    }
  }
}
