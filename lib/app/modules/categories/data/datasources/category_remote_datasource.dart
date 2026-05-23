import '../../../../../core/network/base_remote_service.dart';

abstract class CategoryRemoteDataSource {
  Future<List<Map<String, dynamic>>> listRaw();
}

class CategoryRemoteDataSourceImpl extends BaseRemoteService
    implements CategoryRemoteDataSource {
  CategoryRemoteDataSourceImpl({required super.http});

  @override
  Future<List<Map<String, dynamic>>> listRaw() => getList('/api/categories');
}
