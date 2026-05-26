import '../../../../../core/network/base_remote_service.dart';

abstract class CreditCardRemoteDataSource {
  Future<List<Map<String, dynamic>>> listRaw();
  Future<Map<String, dynamic>> create(Map<String, dynamic> request);
  Future<Map<String, dynamic>> update(String id, Map<String, dynamic> request);
  Future<void> archive(String id);
}

class CreditCardRemoteDataSourceImpl extends BaseRemoteService
    implements CreditCardRemoteDataSource {
  CreditCardRemoteDataSourceImpl({required super.http});

  @override
  Future<List<Map<String, dynamic>>> listRaw() {
    return getList('/api/creditcards');
  }

  @override
  Future<Map<String, dynamic>> create(Map<String, dynamic> request) {
    return postMap('/api/creditcards', body: request);
  }

  @override
  Future<Map<String, dynamic>> update(String id, Map<String, dynamic> request) {
    return putMap('/api/creditcards/$id', body: request);
  }

  @override
  Future<void> archive(String id) {
    return deleteVoid('/api/creditcards/$id');
  }
}
