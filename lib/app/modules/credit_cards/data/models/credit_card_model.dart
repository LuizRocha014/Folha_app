import '../../domain/entities/credit_card_entity.dart';

class CreditCardModel extends CreditCardEntity {
  const CreditCardModel({
    required super.id,
    required super.userId,
    required super.name,
    required super.brand,
    required super.creditLimit,
    required super.closingDay,
    required super.dueDay,
    super.accountId,
    super.lastFour,
    super.isArchived,
    super.syncStatus,
  });

  factory CreditCardModel.fromRow(Map<String, dynamic> row) => CreditCardModel(
        id: row['id'] as String,
        userId: row['user_id'] as String,
        accountId: row['account_id'] as String?,
        name: row['name'] as String,
        brand: (row['brand'] as String?) ?? 'other',
        lastFour: row['last_four'] as String?,
        creditLimit: ((row['credit_limit'] as num?) ?? 0).toDouble(),
        closingDay: ((row['closing_day'] as num?) ?? 1).toInt(),
        dueDay: ((row['due_day'] as num?) ?? 1).toInt(),
        isArchived: ((row['is_archived'] as int?) ?? 0) == 1,
        syncStatus: (row['_sync_status'] as String?) ?? 'synced',
      );

  factory CreditCardModel.fromApiJson(Map<String, dynamic> json) =>
      CreditCardModel(
        id: json['id'] as String,
        userId: json['userId'] as String,
        accountId: json['accountId'] as String?,
        name: (json['name'] as String?) ?? '',
        brand: (json['brand'] as String?) ?? 'other',
        lastFour: json['lastFour'] as String?,
        creditLimit: ((json['creditLimit'] as num?) ?? 0).toDouble(),
        closingDay: ((json['closingDay'] as num?) ?? 1).toInt(),
        dueDay: ((json['dueDay'] as num?) ?? 1).toInt(),
        isArchived: (json['isArchived'] == true),
        syncStatus: 'synced',
      );

  Map<String, dynamic> toApiCreateJson() => {
        // Id do cliente — alinhado com o backend (Id opcional).
        'id': id,
        'accountId': accountId,
        'name': name,
        'brand': brand,
        'lastFour': lastFour,
        'creditLimit': creditLimit,
        'closingDay': closingDay,
        'dueDay': dueDay,
      };

  Map<String, dynamic> toRow() {
    final now = DateTime.now().toUtc().toIso8601String();
    return {
      'id': id,
      'user_id': userId,
      'account_id': accountId,
      'name': name,
      'brand': brand,
      'last_four': lastFour,
      'credit_limit': creditLimit,
      'closing_day': closingDay,
      'due_day': dueDay,
      'is_archived': isArchived ? 1 : 0,
      'created_at': now,
      'updated_at': now,
      '_sync_status': syncStatus,
      '_local_updated_at': DateTime.now().millisecondsSinceEpoch,
    };
  }
}
