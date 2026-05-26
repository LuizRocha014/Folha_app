import '../../../../../core/network/base_remote_service.dart';

abstract class CreditCardInstallmentRemoteDataSource {
  Future<List<Map<String, dynamic>>> listRaw();
  Future<Map<String, dynamic>> create(Map<String, dynamic> request);
  Future<Map<String, dynamic>> update(String id, Map<String, dynamic> request);
  Future<void> delete(String id);
}

class CreditCardInstallmentRemoteDataSourceImpl extends BaseRemoteService
    implements CreditCardInstallmentRemoteDataSource {
  CreditCardInstallmentRemoteDataSourceImpl({required super.http});

  @override
  Future<List<Map<String, dynamic>>> listRaw() {
    return getList('/api/creditcardinstallments');
  }

  @override
  Future<Map<String, dynamic>> create(Map<String, dynamic> request) {
    return postMap('/api/creditcardinstallments', body: request);
  }

  @override
  Future<Map<String, dynamic>> update(String id, Map<String, dynamic> request) {
    return putMap('/api/creditcardinstallments/$id', body: request);
  }

  @override
  Future<void> delete(String id) {
    return deleteVoid('/api/creditcardinstallments/$id');
  }
}
