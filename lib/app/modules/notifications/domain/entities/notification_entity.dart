import 'package:equatable/equatable.dart';

class NotificationEntity extends Equatable {
  final String id;
  final String userId;
  final String kind;
  final String title;
  final String? body;
  final DateTime? scheduledFor;
  final bool isRead;
  final DateTime createdAt;

  const NotificationEntity({
    required this.id,
    required this.userId,
    required this.kind,
    required this.title,
    required this.createdAt,
    this.body,
    this.scheduledFor,
    this.isRead = false,
  });

  @override
  List<Object?> get props => [id, userId, kind, title, body, scheduledFor, isRead, createdAt];
}
