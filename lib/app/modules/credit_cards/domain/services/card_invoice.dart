import '../../../transactions/domain/entities/transaction_entity.dart';
import '../entities/credit_card_installment_entity.dart';

/// Nota das transações geradas automaticamente a partir de um parcelamento.
/// Usada para distinguir essas parcelas das compras avulsas na fatura.
const String kInstallmentTxNote = 'Parcela gerada automaticamente';

/// Uma linha de parcelamento na fatura (com a parcela do mês corrente).
class InstallmentLine {
  const InstallmentLine({
    required this.plan,
    required this.currentNumber,
    required this.active,
  });

  final CreditCardInstallmentEntity plan;

  /// Número da parcela referente ao mês corrente (1..total), limitado ao total.
  final int currentNumber;

  /// `true` se há uma parcela vencendo no mês corrente (entra no total do mês).
  final bool active;

  double get monthlyAmount => plan.installmentAmount;
  String get progressLabel => '$currentNumber/${plan.installmentTotal}';
}

/// Fatura calculada de um cartão para o mês corrente.
class CardInvoice {
  const CardInvoice({
    required this.parcelasDoMes,
    required this.comprasDoMes,
    required this.total,
    required this.installmentLines,
    required this.purchases,
    required this.payments,
  });

  final double parcelasDoMes;
  final double comprasDoMes;
  final double total;
  final List<InstallmentLine> installmentLines;

  /// Compras avulsas do mês (exclui as parcelas geradas automaticamente).
  final List<TransactionEntity> purchases;

  /// Pagamentos da fatura no mês (entradas no cartão). Vazio até existir a feature.
  final List<TransactionEntity> payments;

  /// Parcelamentos que ainda contribuem no mês.
  List<InstallmentLine> get activeInstallments =>
      installmentLines.where((l) => l.active).toList();
}

/// Lógica pura de cálculo da fatura. Sem dependências de banco/UI — recebe os
/// dados já carregados. A regra de avanço das parcelas espelha o
/// `InstallmentMaterializer` (mesma matemática de mês/fechamento).
class CardInvoiceCalculator {
  static CardInvoice compute({
    required int closingDay,
    required List<CreditCardInstallmentEntity> plans,
    required List<TransactionEntity> cardTransactions,
    DateTime? reference,
  }) {
    final now = reference ?? DateTime.now();

    // ── Parcelamentos ──────────────────────────────────────────
    final lines = <InstallmentLine>[];
    for (final plan in plans) {
      final start = plan.startDate;
      final monthsSinceStart =
          (now.year - start.year) * 12 + (now.month - start.month);

      // Parcela referente ao mês corrente. No mês de início é a P+1 (primeira a
      // vencer daqui pra frente). NÃO dependemos do dia de fechamento para
      // EXIBIR — a parcela já faz parte da fatura corrente assim que o cartão é
      // criado (o materializer é quem espera o fechamento pra virar transação).
      final rawCurrent = plan.installmentsPaid + 1 + monthsSinceStart;
      final capped = rawCurrent < 1
          ? 1
          : (rawCurrent > plan.installmentTotal
              ? plan.installmentTotal
              : rawCurrent);
      // Ativa enquanto o plano não terminou (parcela do mês dentro de 1..total).
      final active = monthsSinceStart >= 0 &&
          rawCurrent >= 1 &&
          rawCurrent <= plan.installmentTotal;

      lines.add(InstallmentLine(
        plan: plan,
        currentNumber: capped,
        active: active,
      ));
    }
    final parcelasDoMes = lines
        .where((l) => l.active)
        .fold<double>(0, (sum, l) => sum + l.monthlyAmount);

    // ── Compras e pagamentos do mês ────────────────────────────
    final monthTxs = cardTransactions.where(
      (t) => t.when.year == now.year && t.when.month == now.month,
    );
    final purchases = monthTxs
        .where((t) => t.value < 0 && t.note != kInstallmentTxNote)
        .toList()
      ..sort((a, b) => b.when.compareTo(a.when));
    final payments = monthTxs.where((t) => t.value > 0).toList()
      ..sort((a, b) => b.when.compareTo(a.when));

    final comprasDoMes =
        purchases.fold<double>(0, (sum, t) => sum + t.value.abs());

    return CardInvoice(
      parcelasDoMes: parcelasDoMes,
      comprasDoMes: comprasDoMes,
      total: parcelasDoMes + comprasDoMes,
      installmentLines: lines,
      purchases: purchases,
      payments: payments,
    );
  }
}
