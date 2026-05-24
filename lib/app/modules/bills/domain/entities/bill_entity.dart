import 'package:equatable/equatable.dart';

enum BillStatus { pending, paid, overdue, received, cancelled }

extension BillStatusX on BillStatus {
  String get id => switch (this) {
    BillStatus.pending => 'pending',
    BillStatus.paid => 'paid',
    BillStatus.overdue => 'overdue',
    BillStatus.received => 'received',
    BillStatus.cancelled => 'cancelled',
  };

  static BillStatus parse(String s) => switch (s) {
    'paid' => BillStatus.paid,
    'overdue' => BillStatus.overdue,
    'received' => BillStatus.received,
    'cancelled' => BillStatus.cancelled,
    _ => BillStatus.pending,
  };
}

/// `amount` na entidade é signed (positivo = a pagar, negativo = a receber)
/// para a UI atual continuar funcionando. O remote_datasource traduz para
/// `amount > 0` + `kind` da API.
class BillEntity extends Equatable {
  final String id;
  final String userId;
  final String description;
  final double amount;

  /// Vencimento. `null` quando o usuário ainda não definiu uma data
  /// (ex.: conta avulsa sem boleto). UI deve renderizar "Sem vencimento"
  /// e nunca marcar como overdue.
  final DateTime? due;
  final BillStatus status;
  final String? recurring;
  final String? categorySlug;
  final String? accountId;
  final String? notes;

  /// Valor já pago (acumulado) — usado em "pagar valor parcial".
  /// Sempre não-negativo. Quando `paidAmount >= amount.abs()`, a conta é
  /// promovida para `paid`/`received` automaticamente.
  final double paidAmount;

  /// Parcela atual e total quando for um pagamento parcelado (ex.: 3 de 12).
  /// Ambos null quando a conta não é parcelada.
  final int? installmentCurrent;
  final int? installmentTotal;

  final String syncStatus;

  const BillEntity({
    required this.id,
    required this.userId,
    required this.description,
    required this.amount,
    this.due,
    required this.status,
    this.recurring,
    this.categorySlug,
    this.accountId,
    this.notes,
    this.paidAmount = 0,
    this.installmentCurrent,
    this.installmentTotal,
    this.syncStatus = 'synced',
  });

  bool get isPayable => amount > 0;
  bool get isSettled => status == BillStatus.paid || status == BillStatus.received;

  /// Valor que ainda falta pagar (sempre não-negativo).
  double get remainingAmount {
    final remaining = amount.abs() - paidAmount;
    return remaining < 0 ? 0 : remaining;
  }

  /// % do valor pago (0..1).
  double get paidProgress {
    final total = amount.abs();
    if (total <= 0) return 0;
    return (paidAmount / total).clamp(0.0, 1.0);
  }

  /// `true` se há ao menos um pagamento parcial registrado mas a conta ainda
  /// não foi quitada.
  bool get hasPartialPayment =>
      paidAmount > 0 && !isSettled && paidAmount < amount.abs();

  bool get isInstallment =>
      installmentTotal != null && installmentTotal! > 1;

  /// "3/12" — usado em badges/etiquetas compactas.
  String? get installmentLabel {
    if (!isInstallment) return null;
    return '$installmentCurrent/$installmentTotal';
  }

  BillEntity copyWith({
    BillStatus? status,
    String? syncStatus,
    double? paidAmount,
  }) {
    return BillEntity(
      id: id,
      userId: userId,
      description: description,
      amount: amount,
      due: due,
      status: status ?? this.status,
      recurring: recurring,
      categorySlug: categorySlug,
      accountId: accountId,
      notes: notes,
      paidAmount: paidAmount ?? this.paidAmount,
      installmentCurrent: installmentCurrent,
      installmentTotal: installmentTotal,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  @override
  List<Object?> get props => [
        id, userId, description, amount, due, status, recurring,
        categorySlug, accountId, notes, paidAmount,
        installmentCurrent, installmentTotal, syncStatus,
      ];
}
