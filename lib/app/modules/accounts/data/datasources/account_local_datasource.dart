import 'package:sqflite_sqlcipher/sqflite.dart';
import '../../../../../core/database/local_database.dart';
import '../models/account_model.dart';

class AccountLocalDataSource {
  AccountLocalDataSource(this._db);

  final LocalDatabase _db;

  Future<List<AccountModel>> list({bool includeArchived = false}) async {
    final rows = await _db.raw.query(
      'accounts',
      where: includeArchived ? 'user_id = ?' : 'user_id = ? AND is_archived = 0',
      whereArgs: [_db.userId],
      orderBy: 'sort_order, name',
    );
    return rows.map(AccountModel.fromRow).toList();
  }

  Future<AccountModel?> getById(String id) async {
    final rows = await _db.raw.query(
      'accounts',
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, _db.userId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return AccountModel.fromRow(rows.first);
  }

  Future<void> upsert(AccountModel acc) async {
    await _db.raw.insert('accounts', acc.toRow(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> upsertSynced(AccountModel acc) async {
    final row = acc.toRow()
      ..['_sync_status'] = 'synced'
      ..['_server_updated_at'] = DateTime.now().millisecondsSinceEpoch;
    await _db.raw.insert('accounts', row, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> swapId(String oldId, String newId) async {
    await _db.raw.rawUpdate(
      'UPDATE accounts SET id = ?, _sync_status = ?, _server_updated_at = ? WHERE id = ?',
      [newId, 'synced', DateTime.now().millisecondsSinceEpoch, oldId],
    );
  }

  Future<void> delete(String id) async {
    await _db.raw.delete('accounts', where: 'id = ? AND user_id = ?', whereArgs: [id, _db.userId]);
  }

  Future<void> replaceSyncedSet(List<AccountModel> serverAccs) async {
    await _db.raw.transaction((txn) async {
      await txn.delete('accounts',
          where: 'user_id = ? AND _sync_status = ?', whereArgs: [_db.userId, 'synced']);
      for (final a in serverAccs) {
        final row = a.toRow()
          ..['_sync_status'] = 'synced'
          ..['_server_updated_at'] = DateTime.now().millisecondsSinceEpoch;
        await txn.insert('accounts', row, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  Future<void> upsertMany(List<AccountModel> serverAccs) async {
    if (serverAccs.isEmpty) return;
    await _db.raw.transaction((txn) async {
      for (final a in serverAccs) {
        final existing = await txn.query(
          'accounts',
          columns: ['_sync_status'],
          where: 'id = ?',
          whereArgs: [a.id],
          limit: 1,
        );
        if (existing.isNotEmpty &&
            (existing.first['_sync_status'] as String?) != 'synced') {
          continue;
        }
        final row = a.toRow()
          ..['_sync_status'] = 'synced'
          ..['_server_updated_at'] = DateTime.now().millisecondsSinceEpoch;
        await txn.insert('accounts', row, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }
}
