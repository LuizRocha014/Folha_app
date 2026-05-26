import '../../domain/entities/goal_entity.dart';

class GoalModel extends GoalEntity {
  const GoalModel({
    required super.id,
    required super.userId,
    required super.title,
    required super.targetAmount,
    super.currentAmount,
    super.accountId,
    super.description,
    super.targetDate,
    super.icon,
    super.colorHex,
    super.isCompleted,
    super.isArchived,
    super.monthlyYieldPercent,
    super.isCdb,
    super.syncStatus,
  });

  factory GoalModel.fromRow(Map<String, dynamic> row) => GoalModel(
        id: row['id'] as String,
        userId: row['user_id'] as String,
        accountId: row['account_id'] as String?,
        title: (row['title'] as String?) ?? '',
        description: row['description'] as String?,
        targetAmount: ((row['target_amount'] as num?) ?? 0).toDouble(),
        currentAmount: ((row['current_amount'] as num?) ?? 0).toDouble(),
        targetDate: row['target_date'] != null
            ? DateTime.tryParse(row['target_date'] as String)
            : null,
        icon: row['icon'] as String?,
        colorHex: row['color_hex'] as String?,
        isCompleted: ((row['is_completed'] as int?) ?? 0) == 1,
        isArchived: ((row['is_archived'] as int?) ?? 0) == 1,
        monthlyYieldPercent:
            (row['monthly_yield_percent'] as num?)?.toDouble(),
        isCdb: ((row['is_cdb'] as int?) ?? 0) == 1,
        syncStatus: (row['_sync_status'] as String?) ?? 'synced',
      );

  /// Payload de criação para a API.
  Map<String, dynamic> toApiCreateJson() => {
        // Id do cliente — alinhado com o backend (Id opcional).
        'id': id,
        'accountId': accountId,
        'title': title,
        'description': description,
        'targetAmount': targetAmount,
        'targetDate': targetDate?.toUtc().toIso8601String(),
        'icon': icon,
        'colorHex': colorHex,
        'monthlyYieldPercent': monthlyYieldPercent,
        'isCdb': isCdb,
      };

  Map<String, dynamic> toRow() {
    final now = DateTime.now().toUtc().toIso8601String();
    return {
      'id': id,
      'user_id': userId,
      'account_id': accountId,
      'title': title,
      'description': description,
      'target_amount': targetAmount,
      'current_amount': currentAmount,
      'target_date': targetDate?.toUtc().toIso8601String(),
      'icon': icon,
      'color_hex': colorHex,
      'is_completed': isCompleted ? 1 : 0,
      'completed_at': null,
      'is_archived': isArchived ? 1 : 0,
      'monthly_yield_percent': monthlyYieldPercent,
      'is_cdb': isCdb ? 1 : 0,
      'created_at': now,
      'updated_at': now,
      '_sync_status': syncStatus,
      '_local_updated_at': DateTime.now().millisecondsSinceEpoch,
    };
  }
}
