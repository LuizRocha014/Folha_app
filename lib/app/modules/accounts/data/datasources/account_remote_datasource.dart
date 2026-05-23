import '../../../../../core/network/base_remote_service.dart';

abstract class AccountRemoteDataSource {
  Future<List<Map<String, dynamic>>> listRaw({DateTime? modifiedSince});
  Future<Map<String, dynamic>> create(Map<String, dynamic> request);
  Future<Map<String, dynamic>> update(String id, Map<String, dynamic> request);
  Future<void> archive(String id);
}

class AccountRemoteDataSourceImpl extends BaseRemoteService
    implements AccountRemoteDataSource {
  AccountRemoteDataSourceImpl({required super.http});

  @override
  Future<List<Map<String, dynamic>>> listRaw({DateTime? modifiedSince}) {
    return getList(
      '/api/accounts',
      query: {
        if (modifiedSince != null)
          'modifiedSince': modifiedSince.toUtc().toIso8601String(),
      },
    );
  }

  @override
  Future<Map<String, dynamic>> create(Map<String, dynamic> request) {
    return postMap('/api/accounts', body: request);
  }

  @override
  Future<Map<String, dynamic>> update(String id, Map<String, dynamic> request) {
    return putMap('/api/accounts/$id', body: request);
  }

  @override
  Future<void> archive(String id) {
    return deleteVoid('/api/accounts/$id');
  }
}
