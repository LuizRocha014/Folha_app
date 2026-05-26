import 'package:sqflite_sqlcipher/sqflite.dart';
import '../../../../../core/database/local_database.dart';
import '../models/credit_card_model.dart';

class CreditCardLocalDataSource {
  CreditCardLocalDataSource(this._db);

  final LocalDatabase _db;

  Future<List<CreditCardModel>> listActive() async {
    final rows = await _db.raw.query(
      'credit_cards',
      where: 'user_id = ? AND is_archived = 0',
      whereArgs: [_db.userId],
      orderBy: 'name',
    );
    return rows.map(CreditCardModel.fromRow).toList();
  }

  Future<CreditCardModel?> getById(String id) async {
    final rows = await _db.raw.query(
      'credit_cards',
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, _db.userId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return CreditCardModel.fromRow(rows.first);
  }

  Future<void> upsert(CreditCardModel card) async {
    await _db.raw.insert(
      'credit_cards',
      card.toRow(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Grava um cartão já sincronizado (vindo do servidor após push de create/update).
  Future<void> upsertSynced(CreditCardModel card) async {
    final row = card.toRow()
      ..['_sync_status'] = 'synced'
      ..['_server_updated_at'] = DateTime.now().millisecondsSinceEpoch;
    await _db.raw.insert(
      'credit_cards',
      row,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Remove o registro local (usado após push de delete/archive).
  Future<void> delete(String id) async {
    await _db.raw.delete(
      'credit_cards',
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, _db.userId],
    );
  }

  /// Substitui o id local pelo id real vindo do servidor após o create sync.
  Future<void> swapId(String oldId, String newId) async {
    await _db.raw.rawUpdate(
      'UPDATE credit_cards SET id = ?, _sync_status = ?, _server_updated_at = ? WHERE id = ?',
      [newId, 'synced', DateTime.now().millisecondsSinceEpoch, oldId],
    );
  }

  /// Merge do conjunto vindo do servidor preservando registros com mudanças
  /// locais pendentes (não-`synced`). Mesma estratégia dos demais syncers.
  Future<void> upsertManyPreservingPending(List<CreditCardModel> serverCards) async {
    await _db.raw.transaction((txn) async {
      for (final card in serverCards) {
        final existing = await txn.query(
          'credit_cards',
          columns: ['_sync_status'],
          where: 'id = ?',
          whereArgs: [card.id],
          limit: 1,
        );
        if (existing.isNotEmpty &&
            (existing.first['_sync_status'] as String?) != 'synced') {
          continue;
        }
        final row = card.toRow()
          ..['_sync_status'] = 'synced'
          ..['_server_updated_at'] = DateTime.now().millisecondsSinceEpoch;
        await txn.insert('credit_cards', row, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  Future<void> archive(String id) async {
    await _db.raw.update(
      'credit_cards',
      {
        'is_archived': 1,
        '_sync_status': 'pending_update',
        '_local_updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, _db.userId],
    );
  }
}
