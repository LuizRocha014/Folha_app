import '../../../../../core/network/base_remote_service.dart';
import '../models/transaction_model.dart';

abstract class TransactionRemoteDataSource {
  Future<List<Map<String, dynamic>>> listRaw({
    int skip = 0,
    int take = 200,
    DateTime? modifiedSince,
  });
  Future<Map<String, dynamic>> create(Map<String, dynamic> request);
  Future<Map<String, dynamic>> update(String id, Map<String, dynamic> request);
  Future<void> delete(String id);
}

class TransactionRemoteDataSourceImpl extends BaseRemoteService
    implements TransactionRemoteDataSource {
  TransactionRemoteDataSourceImpl({required super.http});

  @override
  Future<List<Map<String, dynamic>>> listRaw({
    int skip = 0,
    int take = 200,
    DateTime? modifiedSince,
  }) {
    return getList(
      '/api/transactions',
      query: {
        'skip': skip,
        'take': take,
        if (modifiedSince != null)
          'modifiedSince': modifiedSince.toUtc().toIso8601String(),
      },
    );
  }

  @override
  Future<Map<String, dynamic>> create(Map<String, dynamic> request) {
    return postMap('/api/transactions', body: request);
  }

  @override
  Future<Map<String, dynamic>> update(String id, Map<String, dynamic> request) {
    return putMap('/api/transactions/$id', body: request);
  }

  @override
  Future<void> delete(String id) {
    return deleteVoid('/api/transactions/$id');
  }
}

/// Helper static — converte um Map JSON da API em TransactionModel,
/// passando o slug resolvido pelo CategoryLookup.
TransactionModel mapApiTransaction(
  Map<String, dynamic> json,
  String categorySlug,
) =>
    TransactionModel.fromApiJson(json, categorySlug: categorySlug);
