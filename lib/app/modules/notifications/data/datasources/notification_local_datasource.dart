import '../../../../../core/database/local_database.dart';
import '../models/notification_model.dart';

class NotificationLocalDataSource {
  NotificationLocalDataSource(this._db);

  final LocalDatabase _db;

  Future<List<NotificationModel>> list() async {
    final rows = await _db.raw.query(
      'notifications',
      where: 'user_id = ?',
      whereArgs: [_db.userId],
      orderBy: 'created_at DESC',
    );
    return rows.map(NotificationModel.fromRow).toList();
  }

  Future<void> markRead(String id) async {
    await _db.raw.update(
      'notifications',
      {
        'is_read': 1,
        'read_at': DateTime.now().toUtc().toIso8601String(),
        '_sync_status': 'pending_update',
        '_local_updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, _db.userId],
    );
  }
}
