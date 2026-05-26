import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../../core/routes/app_routes.dart';
import '../../../../../core/theme/folha_colors.dart';
import '../../../../../core/theme/folha_typography.dart';
import '../../../../../core/utils/folha_formatters.dart';
import '../../../../../core/widgets/folha_widgets.dart';
import '../../../transactions/data/datasources/transaction_local_datasource.dart';
import '../../data/datasources/credit_card_installment_local_datasource.dart';
import '../../domain/entities/credit_card_entity.dart';
import '../../domain/services/card_invoice.dart';

/// Fatura do cartão (a "conta" do cartão): total do mês, parcelamentos ativos,
/// compras avulsas do mês e pagamentos.
class CardInvoicePage extends StatefulWidget {
  const CardInvoicePage({super.key});

  @override
  State<CardInvoicePage> createState() => _CardInvoicePageState();
}

class _CardInvoicePageState extends State<CardInvoicePage> {
  late final CreditCardEntity? _card;
  Future<CardInvoice>? _future;

  @override
  void initState() {
    super.initState();
    final card = Get.arguments as CreditCardEntity?;
    _card = card;
    if (card != null) _future = _load(card);
  }

  Future<CardInvoice> _load(CreditCardEntity card) async {
    final installmentLocal = Get.find<CreditCardInstallmentLocalDataSource>();
    final txLocal = Get.find<TransactionLocalDataSource>();
    final plans = await installmentLocal.listByCard(card.id);
    final txs = await txLocal.listByCreditCard(card.id);
    return CardInvoiceCalculator.compute(
      closingDay: card.closingDay,
      plans: plans,
      cardTransactions: txs,
    );
  }

  @override
  Widget build(BuildContext context) {
    final card = _card;
    if (card == null) {
      return const Scaffold(body: Center(child: Text('Cartão não encontrado.')));
    }

    return Scaffold(
      backgroundColor: FolhaColors.paper100,
      body: SafeArea(
        child: FutureBuilder<CardInvoice>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            final invoice = snap.data;
            if (invoice == null) {
              return const Center(child: Text('Não consegui montar a fatura.'));
            }
            return _content(context, card, invoice);
          },
        ),
      ),
    );
  }

  Widget _content(BuildContext context, CreditCardEntity card, CardInvoice inv) {
    final active = inv.activeInstallments;
    return SingleChildScrollView(
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'FATURA · ${FolhaFormatters.monthName(DateTime.now()).toUpperCase()}',
                        style: FolhaTypography.eyebrow.copyWith(letterSpacing: 0.66),
                      ),
                      Text(
                        card.name,
                        style: FolhaTypography.titleEditorial(size: 24),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Total do mês
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 8),
            child: Column(
              children: [
                Text(
                  'TOTAL DO MÊS',
                  style: FolhaTypography.eyebrow.copyWith(letterSpacing: 0.66),
                ),
                const SizedBox(height: 6),
                Text(
                  FolhaFormatters.brl(inv.total),
                  style: FolhaTypography.currencyDisplay(size: 48, color: FolhaColors.ink900),
                ),
                const SizedBox(height: 8),
                Text(
                  'Parcelas ${FolhaFormatters.brl(inv.parcelasDoMes)}  ·  '
                  'Compras ${FolhaFormatters.brl(inv.comprasDoMes)}',
                  style: FolhaTypography.bodySm.copyWith(
                    fontSize: 12,
                    color: FolhaColors.fgMuted,
                  ),
                ),
              ],
            ),
          ),

          // Parcelamentos
          _Section(
            title: 'PARCELAMENTOS',
            child: active.isEmpty
                ? _empty('Sem parcelamentos ativos neste mês.')
                : Column(
                    children: List.generate(active.length, (i) {
                      final line = active[i];
                      return _Row(
                        icon: LucideIcons.layers,
                        title: line.plan.description,
                        subtitle: 'Parcela ${line.progressLabel}',
                        trailing: FolhaFormatters.brl(line.monthlyAmount),
                        divider: i < active.length - 1,
                      );
                    }),
                  ),
          ),

          // Compras do mês
          _Section(
            title: 'COMPRAS DO MÊS',
            child: inv.purchases.isEmpty
                ? _empty('Nenhuma compra avulsa no mês.')
                : Column(
                    children: List.generate(inv.purchases.length, (i) {
                      final t = inv.purchases[i];
                      return _Row(
                        icon: LucideIcons.shoppingBag,
                        title: t.description,
                        subtitle: FolhaFormatters.fullDate(t.when),
                        trailing: FolhaFormatters.brl(t.value.abs()),
                        divider: i < inv.purchases.length - 1,
                        onTap: () => Get.toNamed(AppRoutes.transactionDetail, arguments: t),
                      );
                    }),
                  ),
          ),

          // Pagamentos
          _Section(
            title: 'PAGAMENTOS',
            child: inv.payments.isEmpty
                ? _empty('Nenhum pagamento registrado.')
                : Column(
                    children: List.generate(inv.payments.length, (i) {
                      final t = inv.payments[i];
                      return _Row(
                        icon: LucideIcons.check,
                        title: t.description,
                        subtitle: FolhaFormatters.fullDate(t.when),
                        trailing: FolhaFormatters.brl(t.value.abs()),
                        divider: i < inv.payments.length - 1,
                      );
                    }),
                  ),
          ),
        ],
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
            child: Text(
              title,
              style: FolhaTypography.eyebrow.copyWith(letterSpacing: 1.1),
            ),
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
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.divider = false,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String trailing;
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
            top: BorderSide(
              color: divider ? FolhaColors.divider : Colors.transparent,
            ),
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
                    title,
                    style: FolhaTypography.body.copyWith(fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: FolhaTypography.bodySm.copyWith(
                      fontSize: 12,
                      color: FolhaColors.fgMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              trailing,
              style: FolhaTypography.body.copyWith(fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
