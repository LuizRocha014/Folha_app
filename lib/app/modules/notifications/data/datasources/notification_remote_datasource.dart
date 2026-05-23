import '../../../../../core/network/base_remote_service.dart';

abstract class NotificationRemoteDataSource {
  Future<void> markRead(String id);
}

class NotificationRemoteDataSourceImpl extends BaseRemoteService
    implements NotificationRemoteDataSource {
  NotificationRemoteDataSourceImpl({required super.http});

  @override
  Future<void> markRead(String id) {
    return postVoid('/api/notifications/$id/read');
  }
}
