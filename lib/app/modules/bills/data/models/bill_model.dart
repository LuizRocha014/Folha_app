import '../../domain/entities/bill_entity.dart';

class BillModel extends BillEntity {
  const BillModel({
    required super.id,
    required super.description,
    required super.amount,
    required super.due,
    required super.status,
    super.recurring,
  });

  factory BillModel.fromJson(Map<String, dynamic> json) {
    return BillModel(
      id: json['id'] as String,
      description: json['description'] as String,
      amount: (json['amount'] as num).toDouble(),
      due: DateTime.parse(json['due'] as String),
      status: BillStatusX.parse(json['status'] as String),
      recurring: json['recurring'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'description': description,
    'amount': amount,
    'due': due.toIso8601String(),
    'status': status.id,
    'recurring': recurring,
  };
}
