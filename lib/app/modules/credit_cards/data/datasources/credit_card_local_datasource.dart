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
