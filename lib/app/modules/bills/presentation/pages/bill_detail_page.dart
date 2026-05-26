import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../../core/database/local_database.dart';
import '../../../../../core/routes/app_routes.dart';
import '../../../../../core/theme/folha_colors.dart';
import '../../../../../core/theme/folha_typography.dart';
import '../../../../../core/utils/folha_formatters.dart';
import '../../../../../core/widgets/folha_widgets.dart';
import '../../../credit_cards/data/datasources/credit_card_installment_local_datasource.dart';
import '../../../credit_cards/data/datasources/credit_card_local_datasource.dart';
import '../../../credit_cards/domain/services/card_invoice.dart';
import '../../../transactions/data/datasources/transaction_local_datasource.dart';
import '../../domain/entities/bill_entity.dart';
import '../controllers/bills_controller.dart';
import 'partial_payment_dialog.dart';

/// Detalhe de uma conta. Para faturas de cartão ("Fatura ‹Cartão› · Mês")
/// mostra também o detalhamento: parcelamentos e compras do mês.
class BillDetailPage extends StatefulWidget {
  const BillDetailPage({super.key});

  @override
  State<BillDetailPage> createState() => _BillDetailPageState();
}

class _BillDetailPageState extends State<BillDetailPage> {
  BillEntity? _bill;
  CardInvoice? _invoice;
  bool _loadingInvoice = false;

  @override
  void initState() {
    super.initState();
    _bill = Get.arguments as BillEntity?;
    final b = _bill;
    if (b != null && _looksLikeCardFatura(b)) _loadInvoice(b);
  }

  bool _looksLikeCardFatura(BillEntity b) =>
      b.description.startsWith('Fatura ') ||
      (b.notes?.contains('Fatura do cartão') ?? false);

  Future<void> _loadInvoice(BillEntity bill) async {
    if (!Get.isRegistered<LocalDatabase>()) return;
    setState(() => _loadingInvoice = true);
    try {
      final db = Get.find<LocalDatabase>();
      final cards = await CreditCardLocalDataSource(db).listActive();
      final card = cards.firstWhereOrNull((c) => bill.description.contains(c.name));
      if (card == null) return;
      final plans = await CreditCardInstallmentLocalDataSource(db).listByCard(card.id);
      final txs = await TransactionLocalDataSource(db).listByCreditCard(card.id);
      final invoice = CardInvoiceCalculator.compute(
        closingDay: card.closingDay,
        plans: plans,
        cardTransactions: txs,
      );
      if (mounted) setState(() => _invoice = invoice);
    } catch (_) {
      // Sem detalhamento extra — mostra só os dados da conta.
    } finally {
      if (mounted) setState(() => _loadingInvoice = false);
    }
  }

  BillsController? get _ctrl =>
      Get.isRegistered<BillsController>() ? Get.find<BillsController>() : null;

  Future<void> _markPaid(BillEntity bill) async {
    await _ctrl?.markPaid(bill.id);
    if (mounted) Get.back();
  }

  @override
  Widget build(BuildContext context) {
    final bill = _bill;
    if (bill == null) {
      return const Scaffold(body: Center(child: Text('Conta não encontrada.')));
    }
    final isReceivable = bill.amount < 0;
    final paid = bill.isSettled;
    final inv = _invoice;

    return Scaffold(
      backgroundColor: FolhaColors.paper100,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 60),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                child: Row(
                  children: [
                    FolhaIconBtn(
                      icon: LucideIcons.chevronLeft,
                      variant: FolhaIconBtnVariant.soft,
                      tooltip: 'Voltar',
                      onPressed: Get.back,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isReceivable ? 'CONTA A RECEBER' : 'CONTA A PAGAR',
                        style: FolhaTypography.eyebrow.copyWith(letterSpacing: 0.66),
                      ),
                    ),
                  ],
                ),
              ),

              // Hero: descrição + valor + status
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 8),
                child: Column(
                  children: [
                    FolhaStatusPill(status: bill.status.id),
                    const SizedBox(height: 12),
                    Text(
                      bill.description,
                      textAlign: TextAlign.center,
                      style: FolhaTypography.titleEditorial(size: 24),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      FolhaFormatters.brl(bill.amount.abs()),
                      style: FolhaTypography.currencyDisplay(size: 46, color: FolhaColors.ink900),
                    ),
                    if (bill.hasPartialPayment) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Resta ${FolhaFormatters.brl(bill.remainingAmount)} · já pago ${FolhaFormatters.brl(bill.paidAmount)}',
                        style: FolhaTypography.bodySm.copyWith(
                          fontSize: 12,
                          color: FolhaColors.ocre700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Dados da conta
              _Section(
                title: 'DADOS',
                child: Column(
                  children: [
                    _Row(
                      icon: LucideIcons.calendar,
                      label: 'Vencimento',
                      value: bill.due == null
                          ? 'Sem vencimento'
                          : FolhaFormatters.fullDate(bill.due!),
                    ),
                    if (bill.installmentLabel != null)
                      _Row(
                        icon: LucideIcons.layers,
                        label: 'Parcela',
                        value: bill.installmentLabel!,
                        divider: true,
                      ),
                    if (bill.notes != null && bill.notes!.trim().isNotEmpty)
                      _Row(
                        icon: LucideIcons.fileText,
                        label: 'Nota',
                        value: bill.notes!,
                        divider: true,
                      ),
                  ],
                ),
              ),

              // Detalhamento da fatura (parcelamentos + compras), quando aplicável
              if (_loadingInvoice)
                const Padding(
                  padding: EdgeInsets.only(top: 24),
                  child: Center(child: CircularProgressIndicator()),
                ),
              if (inv != null) ...[
                _Section(
                  title: 'PARCELAMENTOS',
                  child: inv.activeInstallments.isEmpty
                      ? _empty('Sem parcelamentos ativos neste mês.')
                      : Column(
                          children: List.generate(inv.activeInstallments.length, (i) {
                            final line = inv.activeInstallments[i];
                            return _Row(
                              icon: LucideIcons.layers,
                              label: line.plan.description,
                              sub: 'Parcela ${line.progressLabel}',
                              value: FolhaFormatters.brl(line.monthlyAmount),
                              divider: i > 0,
                            );
                          }),
                        ),
                ),
                _Section(
                  title: 'COMPRAS DO MÊS',
                  child: inv.purchases.isEmpty
                      ? _empty('Nenhuma compra avulsa no mês.')
                      : Column(
                          children: List.generate(inv.purchases.length, (i) {
                            final t = inv.purchases[i];
                            return _Row(
                              icon: LucideIcons.shoppingBag,
                              label: t.description,
                              sub: FolhaFormatters.fullDate(t.when),
                              value: FolhaFormatters.brl(t.value.abs()),
                              divider: i > 0,
                              onTap: () => Get.toNamed(AppRoutes.transactionDetail, arguments: t),
                            );
                          }),
                        ),
                ),
              ],

              // Ações
              if (!paid)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: FolhaButton(
                          label: isReceivable ? 'Marcar como recebido' : 'Marcar como pago',
                          size: FolhaButtonSize.lg,
                          fullWidth: true,
                          onPressed: () => _markPaid(bill),
                        ),
                      ),
                      const SizedBox(width: 10),
                      FolhaIconBtn(
                        icon: LucideIcons.coins,
                        variant: FolhaIconBtnVariant.soft,
                        size: 48,
                        tooltip: 'Pagar valor parcial',
                        onPressed: () => Get.dialog(PartialPaymentDialog(bill: bill)),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _empty(String text) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Text(
          text,
          style: FolhaTypography.bodySm.copyWith(fontSize: 13, color: FolhaColors.fgMuted),
        ),
      );
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
            child: Text(title, style: FolhaTypography.eyebrow.copyWith(letterSpacing: 1.1)),
          ),
          Container(
            decoration: BoxDecoration(
              color: FolhaColors.paper50,
              border: Border.all(color: FolhaColors.border),
              borderRadius: BorderRadius.circular(14),
            ),
            clipBehavior: Clip.antiAlias,
            child: child,
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.label,
    required this.value,
    this.sub,
    this.divider = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? sub;
  final bool divider;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: divider ? FolhaColors.divider : Colors.transparent),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: FolhaColors.ink400),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: FolhaTypography.body.copyWith(fontWeight: FontWeight.w500),
                  ),
                  if (sub != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      sub!,
                      style: FolhaTypography.bodySm.copyWith(fontSize: 12, color: FolhaColors.fgMuted),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              value,
              textAlign: TextAlign.right,
              style: FolhaTypography.body.copyWith(fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
