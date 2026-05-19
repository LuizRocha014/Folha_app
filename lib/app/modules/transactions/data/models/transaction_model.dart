import '../../domain/entities/transaction_entity.dart';

class TransactionModel extends TransactionEntity {
  const TransactionModel({
    required super.id,
    required super.description,
    required super.place,
    required super.category,
    required super.value,
    required super.when,
    super.note,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as String,
      description: json['description'] as String,
      place: json['place'] as String,
      category: json['category'] as String,
      value: (json['value'] as num).toDouble(),
      when: DateTime.parse(json['when'] as String),
      note: json['note'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'description': description,
    'place': place,
    'category': category,
    'value': value,
    'when': when.toIso8601String(),
    'note': note,
  };
}
