import '../../domain/entities/bill_entity.dart';

class BillModel extends BillEntity {
  const BillModel({
    required super.id,
    required super.userId,
    required super.description,
    required super.amount,
    required super.due,
    required super.status,
    super.recurring,
    super.categorySlug,
    super.accountId,
    super.notes,
    super.paidAmount,
    super.installmentCurrent,
    super.installmentTotal,
    super.syncStatus,
  });

  /// `BillDto` da Folha.Api → `BillModel`.
  factory BillModel.fromApiJson(Map<String, dynamic> json, {String? categorySlug}) {
    final amount = (json['amount'] as num).toDouble();
    final kind = json['kind'] as String;
    final signed = kind == 'receivable' ? -amount : amount;
    return BillModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      description: (json['description'] as String?) ?? '',
      amount: signed,
      due: DateTime.parse(json['dueDate'] as String),
      status: BillStatusX.parse(json['status'] as String),
      categorySlug: categorySlug,
      accountId: json['accountId'] as String?,
      notes: json['notes'] as String?,
      recurring: (json['recurrenceId'] as String?) != null ? 'recorrente' : null,
      paidAmount: ((json['paidAmount'] as num?) ?? 0).toDouble(),
      installmentCurrent: (json['installmentCurrent'] as num?)?.toInt(),
      installmentTotal: (json['installmentTotal'] as num?)?.toInt(),
      syncStatus: 'synced',
    );
  }

  Map<String, dynamic> toApiCreateJson({int? categoryId}) {
    final kind = amount >= 0 ? 'payable' : 'receivable';
    return {
      // O backend aceita Id opcional vindo do cliente — ao enviar nosso UUID
      // local, o id do servidor já vem igual e dispensa swap pós-criação.
      'id': id,
      'accountId': accountId,
      'categoryId': categoryId,
      'recurrenceId': null,
      'description': description,
      'amount': amount.abs(),
      'kind': kind,
      'dueDate': due.toUtc().toIso8601String(),
      'notes': notes,
      'installmentCurrent': installmentCurrent,
      'installmentTotal': installmentTotal,
    };
  }

  Map<String, dynamic> toApiUpdateJson({int? categoryId}) {
    final kind = amount >= 0 ? 'payable' : 'receivable';
    return {
      'accountId': accountId,
      'categoryId': categoryId,
      'recurrenceId': null,
      'description': description,
      'amount': amount.abs(),
      'kind': kind,
      'dueDate': due.toUtc().toIso8601String(),
      'status': status.id,
      'paidAt': isSettled ? DateTime.now().toUtc().toIso8601String() : null,
      'paidAmount': paidAmount,
      'paidTransactionId': null,
      'installmentCurrent': installmentCurrent,
      'installmentTotal': installmentTotal,
      'notes': notes,
    };
  }

  factory BillModel.fromRow(Map<String, dynamic> row) {
    final amount = (row['amount'] as num).toDouble();
    final kind = row['kind'] as String;
    final signed = kind == 'receivable' ? -amount : amount;
    return BillModel(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      description: row['description'] as String,
      amount: signed,
      due: DateTime.parse(row['due_date'] as String),
      status: BillStatusX.parse(row['status'] as String),
      categorySlug: row['category_slug'] as String?,
      accountId: row['account_id'] as String?,
      notes: row['notes'] as String?,
      paidAmount: ((row['paid_amount'] as num?) ?? 0).toDouble(),
      installmentCurrent: (row['installment_current'] as num?)?.toInt(),
      installmentTotal: (row['installment_total'] as num?)?.toInt(),
      syncStatus: (row['_sync_status'] as String?) ?? 'synced',
    );
  }

  Map<String, dynamic> toRow() {
    final kind = amount >= 0 ? 'payable' : 'receivable';
    final now = DateTime.now().toUtc().toIso8601String();
    return {
      'id': id,
      'user_id': userId,
      'account_id': accountId,
      'category_slug': categorySlug,
      'recurrence_id': null,
      'description': description,
      'amount': amount.abs(),
      'kind': kind,
      'due_date': due.toUtc().toIso8601String(),
      'status': status.id,
      'paid_amount': paidAmount,
      'paid_at': isSettled ? now : null,
      'paid_transaction_id': null,
      'installment_current': installmentCurrent,
      'installment_total': installmentTotal,
      'notes': notes,
      'created_at': now,
      'updated_at': now,
      '_sync_status': syncStatus,
      '_local_updated_at': DateTime.now().millisecondsSinceEpoch,
    };
  }
}
