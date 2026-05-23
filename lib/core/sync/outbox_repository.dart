import 'dart:convert';
import 'package:sqflite_sqlcipher/sqflite.dart';
import '../database/local_database.dart';

class OutboxEntry {
  final int id;
  final String entity;
  final String entityId;
  final String operation;
  final Map<String, dynamic> payload;
  final int attempts;
  final String? lastError;
  final DateTime createdAt;

  const OutboxEntry({
    required this.id,
    required this.entity,
    required this.entityId,
    required this.operation,
    required this.payload,
    required this.attempts,
    required this.lastError,
    required this.createdAt,
  });

  factory OutboxEntry.fromRow(Map<String, dynamic> row) => OutboxEntry(
        id: row['id'] as int,
        entity: row['entity'] as String,
        entityId: row['entity_id'] as String,
        operation: row['operation'] as String,
        payload: jsonDecode(row['payload'] as String) as Map<String, dynamic>,
        attempts: row['attempts'] as int,
        lastError: row['last_error'] as String?,
        createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int, isUtc: true),
      );
}

/// Wrapper sobre a tabela `_outbox` — fila de mudanças locais a propagar pra API.
class OutboxRepository {
  OutboxRepository(this._db);

  final LocalDatabase _db;

  /// Enfileira uma mudança. Se já existir uma operação `create` pendente para o mesmo
  /// `entityId` e a nova for `update`, mantém só o `create` com o payload mais recente
  /// (otimização: o servidor nunca viu esse registro mesmo).
  Future<void> enqueue({
    required String entity,
    required String entityId,
    required String operation,
    required Map<String, dynamic> payload,
  }) async {
    final raw = _db.raw;
    final pending = await raw.query(
      '_outbox',
      where: 'entity = ? AND entity_id = ? AND processed_at IS NULL',
      whereArgs: [entity, entityId],
      orderBy: 'id ASC',
    );

    if (pending.isNotEmpty) {
      final last = pending.last;
      final lastOp = last['operation'] as String;
      // create + update → manter create com payload novo
      if (lastOp == 'create' && operation == 'update') {
        await raw.update('_outbox', {
          'payload': jsonEncode(payload),
        }, where: 'id = ?', whereArgs: [last['id']]);
        return;
      }
      // create + delete → cancela o create
      if (lastOp == 'create' && operation == 'delete') {
        await raw.delete('_outbox', where: 'id = ?', whereArgs: [last['id']]);
        return;
      }
      // update + update → substitui payload
      if (lastOp == 'update' && operation == 'update') {
        await raw.update('_outbox', {
          'payload': jsonEncode(payload),
        }, where: 'id = ?', whereArgs: [last['id']]);
        return;
      }
    }

    await raw.insert('_outbox', {
      'entity': entity,
      'entity_id': entityId,
      'operation': operation,
      'payload': jsonEncode(payload),
      'attempts': 0,
      'last_error': null,
      'created_at': DateTime.now().toUtc().millisecondsSinceEpoch,
      'processed_at': null,
    });
  }

  Future<List<OutboxEntry>> pending({String? entity, int limit = 100}) async {
    final rows = await _db.raw.query(
      '_outbox',
      where: entity == null ? 'processed_at IS NULL' : 'processed_at IS NULL AND entity = ?',
      whereArgs: entity == null ? null : [entity],
      orderBy: 'id ASC',
      limit: limit,
    );
    return rows.map(OutboxEntry.fromRow).toList();
  }

  Future<void> markProcessed(int id) async {
    await _db.raw.update(
      '_outbox',
      {'processed_at': DateTime.now().toUtc().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> markFailed(int id, String error) async {
    await _db.raw.rawUpdate(
      'UPDATE _outbox SET attempts = attempts + 1, last_error = ? WHERE id = ?',
      [error, id],
    );
  }

  Future<int> pendingCount({String? entity}) async {
    final result = entity == null
        ? await _db.raw.rawQuery('SELECT COUNT(*) AS c FROM _outbox WHERE processed_at IS NULL')
        : await _db.raw.rawQuery(
            'SELECT COUNT(*) AS c FROM _outbox WHERE processed_at IS NULL AND entity = ?',
            [entity],
          );
    return (result.first['c'] as int?) ?? 0;
  }

  /// Limpa entradas processadas mais antigas que [retention].
  Future<int> purgeOld({Duration retention = const Duration(days: 7)}) async {
    final cutoff = DateTime.now().toUtc().subtract(retention).millisecondsSinceEpoch;
    return _db.raw.delete(
      '_outbox',
      where: 'processed_at IS NOT NULL AND processed_at < ?',
      whereArgs: [cutoff],
    );
  }
}

/// Helper para evitar import direto de sqflite em outros arquivos.
typedef OutboxConflict = ConflictAlgorithm;
