import '../../../../../core/network/base_remote_service.dart';

abstract class BillRemoteDataSource {
  Future<List<Map<String, dynamic>>> listRaw({DateTime? modifiedSince});
  Future<Map<String, dynamic>> create(Map<String, dynamic> request);
  Future<Map<String, dynamic>> update(String id, Map<String, dynamic> request);
  Future<void> delete(String id);
}

class BillRemoteDataSourceImpl extends BaseRemoteService
    implements BillRemoteDataSource {
  BillRemoteDataSourceImpl({required super.http});

  @override
  Future<List<Map<String, dynamic>>> listRaw({DateTime? modifiedSince}) {
    return getList(
      '/api/bills',
      query: {
        if (modifiedSince != null)
          'modifiedSince': modifiedSince.toUtc().toIso8601String(),
      },
    );
  }

  @override
  Future<Map<String, dynamic>> create(Map<String, dynamic> request) {
    return postMap('/api/bills', body: request);
  }

  @override
  Future<Map<String, dynamic>> update(String id, Map<String, dynamic> request) {
    return putMap('/api/bills/$id', body: request);
  }

  @override
  Future<void> delete(String id) {
    return deleteVoid('/api/bills/$id');
  }
}
