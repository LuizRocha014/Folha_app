import 'package:sqflite_sqlcipher/sqflite.dart';
import '../../../../../core/database/local_database.dart';
import '../models/credit_card_installment_model.dart';

class CreditCardInstallmentLocalDataSource {
  CreditCardInstallmentLocalDataSource(this._db);

  final LocalDatabase _db;

  Future<List<CreditCardInstallmentModel>> listAll() async {
    final rows = await _db.raw.query(
      'credit_card_installments',
      where: 'user_id = ?',
      whereArgs: [_db.userId],
      orderBy: 'created_at',
    );
    return rows.map(CreditCardInstallmentModel.fromRow).toList();
  }

  Future<List<CreditCardInstallmentModel>> listByCard(String creditCardId) async {
    final rows = await _db.raw.query(
      'credit_card_installments',
      where: 'credit_card_id = ? AND user_id = ?',
      whereArgs: [creditCardId, _db.userId],
      orderBy: 'created_at',
    );
    return rows.map(CreditCardInstallmentModel.fromRow).toList();
  }

  Future<CreditCardInstallmentModel?> getById(String id) async {
    final rows = await _db.raw.query(
      'credit_card_installments',
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, _db.userId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return CreditCardInstallmentModel.fromRow(rows.first);
  }

  Future<void> upsert(CreditCardInstallmentModel installment) async {
    await _db.raw.insert(
      'credit_card_installments',
      installment.toRow(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> upsertSynced(CreditCardInstallmentModel installment) async {
    final row = installment.toRow()
      ..['_sync_status'] = 'synced'
      ..['_server_updated_at'] = DateTime.now().millisecondsSinceEpoch;
    await _db.raw.insert(
      'credit_card_installments',
      row,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> delete(String id) async {
    await _db.raw.delete(
      'credit_card_installments',
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, _db.userId],
    );
  }

  /// Merge do conjunto do servidor preservando registros locais pendentes.
  Future<void> upsertManyPreservingPending(
      List<CreditCardInstallmentModel> serverItems) async {
    await _db.raw.transaction((txn) async {
      for (final item in serverItems) {
        final existing = await txn.query(
          'credit_card_installments',
          columns: ['_sync_status'],
          where: 'id = ?',
          whereArgs: [item.id],
          limit: 1,
        );
        if (existing.isNotEmpty &&
            (existing.first['_sync_status'] as String?) != 'synced') {
          continue;
        }
        final row = item.toRow()
          ..['_sync_status'] = 'synced'
          ..['_server_updated_at'] = DateTime.now().millisecondsSinceEpoch;
        await txn.insert('credit_card_installments', row,
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }
}
