import '../../../../../core/network/base_remote_service.dart';

abstract class GoalRemoteDataSource {
  Future<Map<String, dynamic>> create(Map<String, dynamic> request);
}

class GoalRemoteDataSourceImpl extends BaseRemoteService
    implements GoalRemoteDataSource {
  GoalRemoteDataSourceImpl({required super.http});

  @override
  Future<Map<String, dynamic>> create(Map<String, dynamic> request) {
    return postMap('/api/goals', body: request);
  }
}
