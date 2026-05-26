import 'package:sqflite_sqlcipher/sqflite.dart';
import '../../../../../core/database/local_database.dart';
import '../models/transaction_model.dart';

class TransactionLocalDataSource {
  TransactionLocalDataSource(this._db);

  final LocalDatabase _db;

  Future<List<TransactionModel>> list({int limit = 200}) async {
    final rows = await _db.raw.query(
      'transactions',
      where: 'user_id = ?',
      whereArgs: [_db.userId],
      orderBy: 'occurred_at DESC',
      limit: limit,
    );
    return rows.map(TransactionModel.fromRow).toList();
  }

  /// Transações de um cartão específico (mais recentes primeiro).
  Future<List<TransactionModel>> listByCreditCard(String creditCardId, {int limit = 500}) async {
    final rows = await _db.raw.query(
      'transactions',
      where: 'user_id = ? AND credit_card_id = ?',
      whereArgs: [_db.userId, creditCardId],
      orderBy: 'occurred_at DESC',
      limit: limit,
    );
    return rows.map(TransactionModel.fromRow).toList();
  }

  Future<TransactionModel?> getById(String id) async {
    final rows = await _db.raw.query(
      'transactions',
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, _db.userId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return TransactionModel.fromRow(rows.first);
  }

  Future<void> upsert(TransactionModel tx) async {
    await _db.raw.insert(
      'transactions',
      tx.toRow(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> upsertSynced(TransactionModel tx, {int? serverUpdatedMs}) async {
    final row = tx.toRow()
      ..['_sync_status'] = 'synced'
      ..['_server_updated_at'] = serverUpdatedMs ?? DateTime.now().millisecondsSinceEpoch;
    await _db.raw.insert(
      'transactions',
      row,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Substitui o id local pelo id real vindo do servidor após o create sync.
  Future<void> swapId(String oldId, String newId) async {
    await _db.raw.rawUpdate(
      'UPDATE transactions SET id = ?, _sync_status = ?, _server_updated_at = ? WHERE id = ?',
      [newId, 'synced', DateTime.now().millisecondsSinceEpoch, oldId],
    );
  }

  Future<void> markSynced(String id) async {
    await _db.raw.update(
      'transactions',
      {
        '_sync_status': 'synced',
        '_server_updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> delete(String id) async {
    await _db.raw.delete(
      'transactions',
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, _db.userId],
    );
  }

  Future<void> markPendingDelete(String id) async {
    await _db.raw.update(
      'transactions',
      {
        '_sync_status': 'pending_delete',
        '_local_updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, _db.userId],
    );
  }

  /// Replace strategy: apaga todas synced e reinsere as do servidor.
  /// Usado SOMENTE no full re-sync.
  Future<void> replaceSyncedSet(List<TransactionModel> serverTxs) async {
    await _db.raw.transaction((txn) async {
      await txn.delete(
        'transactions',
        where: 'user_id = ? AND _sync_status = ?',
        whereArgs: [_db.userId, 'synced'],
      );
      for (final t in serverTxs) {
        final row = t.toRow()
          ..['_sync_status'] = 'synced'
          ..['_server_updated_at'] = DateTime.now().millisecondsSinceEpoch;
        await txn.insert('transactions', row, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  /// Delta-merge: upsert preservando entradas com `_sync_status != 'synced'`.
  Future<void> upsertMany(List<TransactionModel> serverTxs) async {
    if (serverTxs.isEmpty) return;
    await _db.raw.transaction((txn) async {
      for (final t in serverTxs) {
        final existing = await txn.query(
          'transactions',
          columns: ['_sync_status'],
          where: 'id = ?',
          whereArgs: [t.id],
          limit: 1,
        );
        if (existing.isNotEmpty &&
            (existing.first['_sync_status'] as String?) != 'synced') {
          continue;
        }
        final row = t.toRow()
          ..['_sync_status'] = 'synced'
          ..['_server_updated_at'] = DateTime.now().millisecondsSinceEpoch;
        await txn.insert('transactions', row, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }
}
