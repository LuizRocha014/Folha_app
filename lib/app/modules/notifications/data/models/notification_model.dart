import '../../domain/entities/notification_entity.dart';

class NotificationModel extends NotificationEntity {
  const NotificationModel({
    required super.id,
    required super.userId,
    required super.kind,
    required super.title,
    required super.createdAt,
    super.body,
    super.scheduledFor,
    super.isRead,
  });

  factory NotificationModel.fromRow(Map<String, dynamic> row) => NotificationModel(
        id: row['id'] as String,
        userId: row['user_id'] as String,
        kind: (row['kind'] as String?) ?? 'system',
        title: (row['title'] as String?) ?? '',
        body: row['body'] as String?,
        scheduledFor: row['scheduled_for'] != null
            ? DateTime.tryParse(row['scheduled_for'] as String)
            : null,
        isRead: ((row['is_read'] as int?) ?? 0) == 1,
        createdAt: DateTime.tryParse((row['created_at'] as String?) ?? '') ?? DateTime.now(),
      );
}
