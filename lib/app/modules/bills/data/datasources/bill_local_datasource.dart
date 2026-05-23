import 'package:sqflite_sqlcipher/sqflite.dart';
import '../../../../../core/database/local_database.dart';
import '../models/bill_model.dart';

class BillLocalDataSource {
  BillLocalDataSource(this._db);

  final LocalDatabase _db;

  Future<List<BillModel>> list() async {
    final rows = await _db.raw.query(
      'bills',
      where: 'user_id = ?',
      whereArgs: [_db.userId],
      orderBy: 'due_date',
    );
    return rows.map(BillModel.fromRow).toList();
  }

  Future<BillModel?> getById(String id) async {
    final rows = await _db.raw.query(
      'bills',
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, _db.userId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return BillModel.fromRow(rows.first);
  }

  Future<void> upsert(BillModel bill) async {
    await _db.raw.insert('bills', bill.toRow(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> upsertSynced(BillModel bill) async {
    final row = bill.toRow()
      ..['_sync_status'] = 'synced'
      ..['_server_updated_at'] = DateTime.now().millisecondsSinceEpoch;
    await _db.raw.insert('bills', row, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> swapId(String oldId, String newId) async {
    await _db.raw.rawUpdate(
      'UPDATE bills SET id = ?, _sync_status = ?, _server_updated_at = ? WHERE id = ?',
      [newId, 'synced', DateTime.now().millisecondsSinceEpoch, oldId],
    );
  }

  Future<void> delete(String id) async {
    await _db.raw.delete('bills', where: 'id = ? AND user_id = ?', whereArgs: [id, _db.userId]);
  }

  Future<void> markPendingUpdate(String id) async {
    await _db.raw.update(
      'bills',
      {
        '_sync_status': 'pending_update',
        '_local_updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, _db.userId],
    );
  }

  Future<void> replaceSyncedSet(List<BillModel> serverBills) async {
    await _db.raw.transaction((txn) async {
      await txn.delete('bills',
          where: 'user_id = ? AND _sync_status = ?', whereArgs: [_db.userId, 'synced']);
      for (final b in serverBills) {
        final row = b.toRow()
          ..['_sync_status'] = 'synced'
          ..['_server_updated_at'] = DateTime.now().millisecondsSinceEpoch;
        await txn.insert('bills', row, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  Future<void> upsertMany(List<BillModel> serverBills) async {
    if (serverBills.isEmpty) return;
    await _db.raw.transaction((txn) async {
      for (final b in serverBills) {
        final existing = await txn.query(
          'bills',
          columns: ['_sync_status'],
          where: 'id = ?',
          whereArgs: [b.id],
          limit: 1,
        );
        if (existing.isNotEmpty &&
            (existing.first['_sync_status'] as String?) != 'synced') {
          continue;
        }
        final row = b.toRow()
          ..['_sync_status'] = 'synced'
          ..['_server_updated_at'] = DateTime.now().millisecondsSinceEpoch;
        await txn.insert('bills', row, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }
}
