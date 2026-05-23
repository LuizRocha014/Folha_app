import '../../domain/entities/transaction_entity.dart';

class TransactionModel extends TransactionEntity {
  const TransactionModel({
    required super.id,
    required super.userId,
    required super.description,
    required super.place,
    required super.category,
    required super.value,
    required super.when,
    required super.kind,
    super.accountId,
    super.creditCardId,
    super.billId,
    super.note,
    super.isPending,
    super.isExcludedFromReports,
    super.syncStatus,
  });

  /// Constrói a partir do `TransactionDto` da Folha.Api.
  /// O caller deve resolver o slug a partir do categoryId via `CategoryLookup`.
  factory TransactionModel.fromApiJson(
    Map<String, dynamic> json, {
    required String categorySlug,
  }) {
    final amount = (json['amount'] as num).toDouble();
    final kind = json['kind'] as String;
    final signed = (kind == 'income' || kind == 'transfer_in') ? amount : -amount;
    return TransactionModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      accountId: json['accountId'] as String?,
      creditCardId: json['creditCardId'] as String?,
      billId: json['billId'] as String?,
      description: (json['description'] as String?) ?? '',
      place: (json['place'] as String?) ?? '',
      category: categorySlug,
      value: signed,
      when: DateTime.parse(json['occurredAt'] as String),
      kind: kind,
      note: json['notes'] as String?,
      isPending: (json['isPending'] as bool?) ?? false,
      isExcludedFromReports: (json['isExcludedFromReports'] as bool?) ?? false,
      syncStatus: 'synced',
    );
  }

  /// Serializa pro `CreateTransactionRequest` / `UpdateTransactionRequest` da API.
  Map<String, dynamic> toApiCreateJson({required int categoryId}) {
    final absAmount = value.abs();
    final inferredKind = value >= 0 ? 'income' : 'expense';
    return {
      // O backend aceita Id opcional vindo do cliente — ao enviar nosso UUID
      // local, o id do servidor já vem igual e dispensa swap pós-criação.
      'id': id,
      'accountId': accountId,
      'creditCardId': creditCardId,
      'billId': billId,
      'categoryId': categoryId,
      'description': description,
      'place': place.isEmpty ? null : place,
      'notes': note,
      'amount': absAmount,
      'kind': kind.isEmpty ? inferredKind : kind,
      'occurredAt': when.toUtc().toIso8601String(),
      'isPending': isPending,
      'isExcludedFromReports': isExcludedFromReports,
    };
  }

  Map<String, dynamic> toApiUpdateJson({required int categoryId}) {
    final absAmount = value.abs();
    return {
      'accountId': accountId,
      'creditCardId': creditCardId,
      'creditCardStatementId': null,
      'categoryId': categoryId,
      'description': description,
      'place': place.isEmpty ? null : place,
      'notes': note,
      'amount': absAmount,
      'kind': kind,
      'occurredAt': when.toUtc().toIso8601String(),
      'installmentNumber': null,
      'installmentTotal': null,
      'isPending': isPending,
      'isExcludedFromReports': isExcludedFromReports,
    };
  }

  /// Row do banco local (`transactions` table).
  factory TransactionModel.fromRow(Map<String, dynamic> row) {
    final amount = (row['amount'] as num).toDouble();
    final kind = row['kind'] as String;
    final signed = (kind == 'income' || kind == 'transfer_in') ? amount : -amount;
    return TransactionModel(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      accountId: row['account_id'] as String?,
      creditCardId: row['credit_card_id'] as String?,
      billId: row['bill_id'] as String?,
      description: row['description'] as String,
      place: (row['place'] as String?) ?? '',
      category: row['category_slug'] as String,
      value: signed,
      when: DateTime.parse(row['occurred_at'] as String),
      kind: kind,
      note: row['notes'] as String?,
      isPending: ((row['is_pending'] as int?) ?? 0) == 1,
      isExcludedFromReports: ((row['is_excluded_from_reports'] as int?) ?? 0) == 1,
      syncStatus: (row['_sync_status'] as String?) ?? 'synced',
    );
  }

  Map<String, dynamic> toRow() {
    final absAmount = value.abs();
    return {
      'id': id,
      'user_id': userId,
      'account_id': accountId,
      'credit_card_id': creditCardId,
      'credit_card_statement_id': null,
      'category_slug': category,
      'bill_id': billId,
      'recurrence_id': null,
      'parent_transaction_id': null,
      'transfer_id': null,
      'description': description,
      'place': place.isEmpty ? null : place,
      'notes': note,
      'amount': absAmount,
      'kind': kind,
      'occurred_at': when.toUtc().toIso8601String(),
      'is_pending': isPending ? 1 : 0,
      'is_excluded_from_reports': isExcludedFromReports ? 1 : 0,
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
      '_sync_status': syncStatus,
      '_local_updated_at': DateTime.now().millisecondsSinceEpoch,
    };
  }
}
