import '../../domain/entities/credit_card_installment_entity.dart';

class CreditCardInstallmentModel extends CreditCardInstallmentEntity {
  const CreditCardInstallmentModel({
    required super.id,
    required super.userId,
    required super.creditCardId,
    required super.description,
    required super.installmentTotal,
    required super.installmentsPaid,
    required super.installmentAmount,
    required super.startDate,
    super.syncStatus,
  });

  factory CreditCardInstallmentModel.fromRow(Map<String, dynamic> row) =>
      CreditCardInstallmentModel(
        id: row['id'] as String,
        userId: row['user_id'] as String,
        creditCardId: row['credit_card_id'] as String,
        description: (row['description'] as String?) ?? '',
        installmentTotal: ((row['installment_total'] as num?) ?? 1).toInt(),
        installmentsPaid: ((row['installments_paid'] as num?) ?? 0).toInt(),
        installmentAmount: ((row['installment_amount'] as num?) ?? 0).toDouble(),
        startDate: DateTime.parse(row['start_date'] as String),
        syncStatus: (row['_sync_status'] as String?) ?? 'synced',
      );

  factory CreditCardInstallmentModel.fromApiJson(Map<String, dynamic> json) =>
      CreditCardInstallmentModel(
        id: json['id'] as String,
        userId: json['userId'] as String,
        creditCardId: json['creditCardId'] as String,
        description: (json['description'] as String?) ?? '',
        installmentTotal: ((json['installmentTotal'] as num?) ?? 1).toInt(),
        installmentsPaid: ((json['installmentsPaid'] as num?) ?? 0).toInt(),
        installmentAmount: ((json['installmentAmount'] as num?) ?? 0).toDouble(),
        startDate: DateTime.parse(json['startDate'] as String),
        syncStatus: 'synced',
      );

  Map<String, dynamic> toApiCreateJson() => {
        // Id do cliente — alinhado com o backend (Id opcional).
        'id': id,
        'creditCardId': creditCardId,
        'description': description,
        'installmentTotal': installmentTotal,
        'installmentsPaid': installmentsPaid,
        'installmentAmount': installmentAmount,
        'startDate': _dateOnly(startDate),
      };

  Map<String, dynamic> toApiUpdateJson() => {
        'description': description,
        'installmentTotal': installmentTotal,
        'installmentsPaid': installmentsPaid,
        'installmentAmount': installmentAmount,
        'startDate': _dateOnly(startDate),
      };

  Map<String, dynamic> toRow() {
    final now = DateTime.now().toUtc().toIso8601String();
    return {
      'id': id,
      'user_id': userId,
      'credit_card_id': creditCardId,
      'description': description,
      'installment_total': installmentTotal,
      'installments_paid': installmentsPaid,
      'installment_amount': installmentAmount,
      'start_date': _dateOnly(startDate),
      'created_at': now,
      'updated_at': now,
      '_sync_status': syncStatus,
      '_local_updated_at': DateTime.now().millisecondsSinceEpoch,
    };
  }

  static String _dateOnly(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
