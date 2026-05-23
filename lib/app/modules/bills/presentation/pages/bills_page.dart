import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../../core/theme/folha_colors.dart';
import '../../../../../core/theme/folha_typography.dart';
import '../../../../../core/utils/folha_formatters.dart';
import '../../../../../core/widgets/folha_widgets.dart';
import '../../../shell/presentation/controllers/shell_controller.dart';
import '../../domain/entities/bill_entity.dart';
import '../controllers/bills_controller.dart';
import 'partial_payment_dialog.dart';

class BillsPage extends GetView<BillsController> {
  const BillsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final shell = Get.find<ShellController>();
    return Obx(() {
      final summary = controller.summary;
      final list = controller.filtered;

      return SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 110),
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: Row(
                children: [
                  FolhaIconBtn(
                    icon: LucideIcons.chevronLeft,
                    variant: FolhaIconBtnVariant.soft,
                    tooltip: 'Voltar',
                    onPressed: () => shell.goTo(0),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          FolhaFormatters.monthName(
                            DateTime.now(),
                          ).toUpperCase(),
                          style: FolhaTypography.eyebrow.copyWith(
                            letterSpacing: 0.66,
                          ),
                        ),
                        Text(
                          'Contas',
                          style: FolhaTypography.titleEditorial(size: 24),
                        ),
                      ],
                    ),
                  ),
                  FolhaIconBtn(
                    icon: LucideIcons.calendar,
                    variant: FolhaIconBtnVariant.soft,
                    onPressed: () {},
                  ),
                ],
              ),
            ),

            // Summary hero (dark card)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: FolhaCard(
                dark: true,
                padding: 20,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'A PAGAR ESSE MÊS',
                            style: FolhaTypography.eyebrow.copyWith(
                              color: FolhaColors.paper300,
                              letterSpacing: 1.1,
                            ),
                          ),
                          const SizedBox(height: 6),
                          FolhaCurrency(
                            value: summary.toPay,
                            big: true,
                            size: 42,
                            color: FolhaColors.paper50,
                          ),
                          const SizedBox(height: 12),
                          RichText(
                            text: TextSpan(
                              style: FolhaTypography.body.copyWith(
                                fontSize: 12,
                                color: FolhaColors.forest300,
                              ),
                              children: [
                                TextSpan(
                                  text:
                                      '${summary.count} contas pendentes',
                                ),
                                if (summary.overdue > 0)
                                  TextSpan(
                                    text:
                                        ' · ${summary.overdue} vencida${summary.overdue > 1 ? 's' : ''}',
                                    style: const TextStyle(
                                      color: FolhaColors.terra300,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      LucideIcons.wallet,
                      size: 28,
                      color: FolhaColors.forest400,
                    ),
                  ],
                ),
              ),
            ),

            // Tab switcher
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: FolhaColors.paper200,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  children: [
                    _TabBtn(id: 'pay', label: 'A pagar'),
                    _TabBtn(id: 'receive', label: 'A receber'),
                  ],
                ),
              ),
            ),

            // List
            const SizedBox(height: 18),
            ...list.map(
              (b) => Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                child: _BillCard(bill: b),
              ),
            ),
            if (list.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: FolhaColors.paper50,
                    border: Border.all(
                      color: FolhaColors.borderStrong,
                      style: BorderStyle.solid,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        LucideIcons.leaf,
                        size: 28,
                        color: FolhaColors.ink300,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sem contas ${controller.tab.value == 'pay' ? 'a pagar' : 'a receber'}.',
                        style: FolhaTypography.titleEditorial(
                          size: 16,
                          color: FolhaColors.ink700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }
}

class _TabBtn extends GetView<BillsController> {
  final String id;
  final String label;
  const _TabBtn({required this.id, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Obx(() {
        final active = controller.tab.value == id;
        return Material(
          color: active ? FolhaColors.paper50 : Colors.transparent,
          shape: const StadiumBorder(),
          elevation: active ? 1 : 0,
          shadowColor: FolhaColors.ink900.withValues(alpha: 0.06),
          child: InkWell(
            onTap: () => controller.tab.value = id,
            customBorder: const StadiumBorder(),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              child: Center(
                child: Text(
                  label,
                  style: FolhaTypography.body.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: active
                        ? FolhaColors.forest700
                        : FolhaColors.fgMuted,
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _BillCard extends GetView<BillsController> {
  final BillEntity bill;
  const _BillCard({required this.bill});

  void _openMoreMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: FolhaColors.paper100,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: FolhaColors.ink200,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 12),
                _MenuTile(
                  icon: LucideIcons.coins,
                  iconColor: FolhaColors.ocre700,
                  title: 'Pagar valor parcial',
                  subtitle:
                      'Resta ${FolhaFormatters.brl(bill.remainingAmount)}',
                  onTap: () {
                    Navigator.of(sheetCtx).pop();
                    Get.dialog(PartialPaymentDialog(bill: bill));
                  },
                ),
                _MenuTile(
                  icon: LucideIcons.x,
                  iconColor: FolhaColors.ink700,
                  title: 'Cancelar',
                  onTap: () => Navigator.of(sheetCtx).pop(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Confirma a quitação total — ação irreversível, então alerta o usuário
  /// antes de marcar.
  Future<void> _confirmMarkPaid(BuildContext context) async {
    final isReceivable = bill.amount < 0;
    final label = isReceivable ? 'recebido' : 'pago';
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        backgroundColor: FolhaColors.paper100,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
        actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: FolhaColors.terra100,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.triangleAlert,
                size: 18,
                color: FolhaColors.terra700,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Marcar como $label?',
                style: FolhaTypography.titleEditorial(size: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              bill.description,
              style: FolhaTypography.body.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              FolhaFormatters.brl(bill.amount.abs()),
              style: FolhaTypography.currency(
                size: 20,
                weight: FontWeight.w600,
                color: FolhaColors.ink900,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Essa ação não pode ser desfeita. A conta vai para o histórico '
              'como quitada.',
              style: FolhaTypography.bodySm.copyWith(
                fontSize: 13,
                color: FolhaColors.ink700,
                height: 1.4,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text(
              'Cancelar',
              style: FolhaTypography.body.copyWith(
                fontSize: 13,
                color: FolhaColors.fgMuted,
              ),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: FolhaColors.forest700,
              foregroundColor: FolhaColors.paper50,
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: const StadiumBorder(),
            ),
            onPressed: () => Get.back(result: true),
            child: Text(
              'Sim, marcar',
              style: FolhaTypography.body.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: FolhaColors.paper50,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await controller.markPaid(bill.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final overdue = bill.status == BillStatus.overdue;
    final paid = bill.isSettled;
    final showProgress = bill.hasPartialPayment;

    return AnimatedOpacity(
      opacity: paid ? 0.6 : 1,
      duration: const Duration(milliseconds: 200),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: FolhaColors.paper50,
          border: Border.all(color: FolhaColors.border),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          FolhaStatusPill(status: bill.status.id),
                          if (bill.recurring != null)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  LucideIcons.calendar,
                                  size: 11,
                                  color: FolhaColors.fgMuted,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  bill.recurring!.toUpperCase(),
                                  style: FolhaTypography.eyebrow.copyWith(
                                    fontSize: 10,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ],
                            ),
                          if (bill.installmentLabel != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: FolhaColors.ocre100,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    LucideIcons.layers,
                                    size: 11,
                                    color: FolhaColors.ocre700,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Parc. ${bill.installmentLabel}',
                                    style: FolhaTypography.eyebrow.copyWith(
                                      fontSize: 10,
                                      letterSpacing: 0.4,
                                      color: FolhaColors.ocre700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        bill.description,
                        style: FolhaTypography.body.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: FolhaColors.ink900,
                          decoration: paid
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${overdue ? "Venceu" : "Vence"} ${FolhaFormatters.relativeDay(bill.due).toLowerCase()}',
                        style: FolhaTypography.bodySm.copyWith(
                          fontSize: 12,
                          color: overdue
                              ? FolhaColors.terra700
                              : FolhaColors.fgMuted,
                          fontWeight:
                              overdue ? FontWeight.w500 : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      FolhaFormatters.brl(bill.amount.abs()),
                      style: FolhaTypography.currency(
                        size: 18,
                        weight: FontWeight.w500,
                        color: FolhaColors.ink900,
                      ),
                    ),
                    if (showProgress)
                      Text(
                        'resta ${FolhaFormatters.brl(bill.remainingAmount)}',
                        style: FolhaTypography.bodySm.copyWith(
                          fontSize: 11,
                          color: FolhaColors.ocre700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            if (showProgress) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: bill.paidProgress,
                  minHeight: 6,
                  backgroundColor: FolhaColors.paper200,
                  valueColor: const AlwaysStoppedAnimation(
                    FolhaColors.forest500,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Já pago: ${FolhaFormatters.brl(bill.paidAmount)} de '
                '${FolhaFormatters.brl(bill.amount.abs())}',
                style: FolhaTypography.bodySm.copyWith(
                  fontSize: 11,
                  color: FolhaColors.fgMuted,
                ),
              ),
            ],
            if (!paid) ...[
              const SizedBox(height: 12),
              Container(height: 1, color: FolhaColors.divider),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FolhaButton(
                      label: bill.amount > 0
                          ? 'Marcar como pago'
                          : 'Marcar como recebido',
                      size: FolhaButtonSize.sm,
                      onPressed: () => _confirmMarkPaid(context),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FolhaIconBtn(
                    icon: LucideIcons.moreHorizontal,
                    variant: FolhaIconBtnVariant.soft,
                    size: 36,
                    onPressed: () => _openMoreMenu(context),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Linha do menu "⋯" no card de uma conta — substitui `ListTile` para evitar
/// o warning de Material ancestor e ficar alinhado com a UI Folha.
class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: FolhaTypography.body.copyWith(fontSize: 14),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: FolhaTypography.bodySm.copyWith(
                        fontSize: 11,
                        color: FolhaColors.fgMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
