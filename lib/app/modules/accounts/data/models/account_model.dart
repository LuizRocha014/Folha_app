import '../../domain/entities/account_entity.dart';

class AccountModel extends AccountEntity {
  const AccountModel({
    required super.id,
    required super.userId,
    required super.name,
    required super.kind,
    super.institution,
    super.icon,
    super.colorHex,
    super.initialBalance,
    super.currencyCode,
    super.isArchived,
    super.includeInTotal,
    super.sortOrder,
    super.syncStatus,
  });

  factory AccountModel.fromApiJson(Map<String, dynamic> json) => AccountModel(
        id: json['id'] as String,
        userId: json['userId'] as String,
        name: (json['name'] as String?) ?? '',
        kind: (json['kind'] as String?) ?? 'checking',
        institution: json['institution'] as String?,
        icon: json['icon'] as String?,
        colorHex: json['colorHex'] as String?,
        initialBalance: ((json['initialBalance'] as num?) ?? 0).toDouble(),
        currencyCode: (json['currencyCode'] as String?) ?? 'BRL',
        isArchived: (json['isArchived'] as bool?) ?? false,
        includeInTotal: (json['includeInTotal'] as bool?) ?? true,
        sortOrder: (json['sortOrder'] as int?) ?? 0,
        syncStatus: 'synced',
      );

  Map<String, dynamic> toApiCreateJson() => {
        // Id do cliente — alinhado com o backend (Id opcional).
        'id': id,
        'name': name,
        'kind': kind,
        'institution': institution,
        'icon': icon,
        'colorHex': colorHex,
        'initialBalance': initialBalance,
        'currencyCode': currencyCode,
        'includeInTotal': includeInTotal,
        'sortOrder': sortOrder,
      };

  Map<String, dynamic> toApiUpdateJson() => {
        'name': name,
        'kind': kind,
        'institution': institution,
        'icon': icon,
        'colorHex': colorHex,
        'initialBalance': initialBalance,
        'currencyCode': currencyCode,
        'isArchived': isArchived,
        'includeInTotal': includeInTotal,
        'sortOrder': sortOrder,
      };

  factory AccountModel.fromRow(Map<String, dynamic> row) => AccountModel(
        id: row['id'] as String,
        userId: row['user_id'] as String,
        name: row['name'] as String,
        kind: row['kind'] as String,
        institution: row['institution'] as String?,
        icon: row['icon'] as String?,
        colorHex: row['color_hex'] as String?,
        initialBalance: ((row['initial_balance'] as num?) ?? 0).toDouble(),
        currencyCode: row['currency_code'] as String,
        isArchived: ((row['is_archived'] as int?) ?? 0) == 1,
        includeInTotal: ((row['include_in_total'] as int?) ?? 1) == 1,
        sortOrder: (row['sort_order'] as int?) ?? 0,
        syncStatus: (row['_sync_status'] as String?) ?? 'synced',
      );

  Map<String, dynamic> toRow() {
    final now = DateTime.now().toUtc().toIso8601String();
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'kind': kind,
      'institution': institution,
      'icon': icon,
      'color_hex': colorHex,
      'initial_balance': initialBalance,
      'currency_code': currencyCode,
      'is_archived': isArchived ? 1 : 0,
      'include_in_total': includeInTotal ? 1 : 0,
      'sort_order': sortOrder,
      'created_at': now,
      'updated_at': now,
      '_sync_status': syncStatus,
      '_local_updated_at': DateTime.now().millisecondsSinceEpoch,
    };
  }
}
