import 'package:equatable/equatable.dart';

class GoalEntity extends Equatable {
  final String id;
  final String userId;
  final String? accountId;
  final String title;
  final String? description;
  final double targetAmount;
  final double currentAmount;
  final DateTime? targetDate;
  final String? icon;
  final String? colorHex;
  final bool isCompleted;
  final bool isArchived;

  /// % de rendimento ao mês informada pelo usuário (ex.: 0.95 para 0,95% a.m.).
  /// Quando null, o app não calcula projeção.
  final double? monthlyYieldPercent;

  /// Marcador "está rendendo via CDB" — usado apenas para exibir o ícone/etiqueta.
  final bool isCdb;

  final String syncStatus;

  const GoalEntity({
    required this.id,
    required this.userId,
    required this.title,
    required this.targetAmount,
    this.currentAmount = 0,
    this.accountId,
    this.description,
    this.targetDate,
    this.icon,
    this.colorHex,
    this.isCompleted = false,
    this.isArchived = false,
    this.monthlyYieldPercent,
    this.isCdb = false,
    this.syncStatus = 'synced',
  });

  double get progress =>
      targetAmount <= 0 ? 0 : (currentAmount / targetAmount).clamp(0.0, 1.0);

  int? get daysLeft {
    if (targetDate == null) return null;
    return targetDate!.difference(DateTime.now()).inDays;
  }

  /// Rendimento estimado para o próximo mês: `valor_guardado * (% / 100)`.
  /// Retorna null se não há % informada ou o valor guardado é zero.
  double? get estimatedMonthlyYield {
    final pct = monthlyYieldPercent;
    if (pct == null || pct <= 0 || currentAmount <= 0) return null;
    return currentAmount * (pct / 100);
  }

  @override
  List<Object?> get props => [
        id, userId, title, targetAmount, currentAmount, targetDate,
        isCompleted, isArchived, monthlyYieldPercent, isCdb, syncStatus,
      ];
}
