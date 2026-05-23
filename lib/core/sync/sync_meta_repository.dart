import 'package:sqflite_sqlcipher/sqflite.dart';
import '../database/local_database.dart';

/// Cursor por entidade: armazena `last_pulled_at` e `last_pushed_at` em ms epoch.
/// Usado pelos syncers pra pedir só registros modificados desde o último pull.
class SyncMetaRepository {
  SyncMetaRepository(this._db);

  final LocalDatabase _db;

  Future<DateTime?> readLastPulledAt(String entity) async {
    final rows = await _db.raw.query(
      '_sync_meta',
      columns: ['last_pulled_at'],
      where: 'entity = ?',
      whereArgs: [entity],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final ms = rows.first['last_pulled_at'] as int?;
    if (ms == null || ms == 0) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
  }

  Future<void> markPulled(String entity, DateTime when) async {
    await _db.raw.insert(
      '_sync_meta',
      {
        'entity': entity,
        'last_pulled_at': when.toUtc().millisecondsSinceEpoch,
        'last_pushed_at': 0,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
    await _db.raw.update(
      '_sync_meta',
      {'last_pulled_at': when.toUtc().millisecondsSinceEpoch},
      where: 'entity = ?',
      whereArgs: [entity],
    );
  }

  Future<void> markPushed(String entity, DateTime when) async {
    await _db.raw.insert(
      '_sync_meta',
      {
        'entity': entity,
        'last_pulled_at': 0,
        'last_pushed_at': when.toUtc().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
    await _db.raw.update(
      '_sync_meta',
      {'last_pushed_at': when.toUtc().millisecondsSinceEpoch},
      where: 'entity = ?',
      whereArgs: [entity],
    );
  }

  /// Limpa cursor (útil em logout/full re-sync).
  Future<void> reset(String entity) async {
    await _db.raw.update(
      '_sync_meta',
      {'last_pulled_at': 0, 'last_pushed_at': 0},
      where: 'entity = ?',
      whereArgs: [entity],
    );
  }
}
