import 'package:sqflite_sqlcipher/sqflite.dart';
import '../../../../../core/database/local_database.dart';
import '../models/goal_model.dart';

class GoalLocalDataSource {
  GoalLocalDataSource(this._db);

  final LocalDatabase _db;

  Future<List<GoalModel>> list({bool includeArchived = false}) async {
    final rows = await _db.raw.query(
      'goals',
      where: includeArchived ? 'user_id = ?' : 'user_id = ? AND is_archived = 0',
      whereArgs: [_db.userId],
      orderBy: 'created_at DESC',
    );
    return rows.map(GoalModel.fromRow).toList();
  }

  Future<void> upsert(GoalModel goal) async {
    await _db.raw.insert('goals', goal.toRow(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
