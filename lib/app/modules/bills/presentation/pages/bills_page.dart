import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../../core/theme/folha_colors.dart';
import '../../../../../core/theme/folha_typography.dart';
import '../../../../../core/utils/folha_formatters.dart';
import '../../../../../core/widgets/folha_widgets.dart';
import '../../../shell/presentation/controllers/shell_controller.dart';
import '../../domain/entities/bill_entity.dart';
import '../controllers/bills_controller.dart';

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

  @override
  Widget build(BuildContext context) {
    final overdue = bill.status == BillStatus.overdue;
    final paid = bill.isSettled;

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
                      Row(
                        children: [
                          FolhaStatusPill(status: bill.status.id),
                          if (bill.recurring != null) ...[
                            const SizedBox(width: 8),
                            Row(
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
                          ],
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
                Text(
                  FolhaFormatters.brl(bill.amount.abs()),
                  style: FolhaTypography.currency(
                    size: 18,
                    weight: FontWeight.w500,
                    color: FolhaColors.ink900,
                  ),
                ),
              ],
            ),
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
                      onPressed: () => controller.markPaid(bill.id),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FolhaIconBtn(
                    icon: LucideIcons.moreHorizontal,
                    variant: FolhaIconBtnVariant.soft,
                    size: 36,
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
