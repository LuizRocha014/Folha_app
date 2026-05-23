import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../../core/routes/app_routes.dart';
import '../../../../../core/theme/folha_colors.dart';
import '../../../../../core/theme/folha_typography.dart';
import '../../../../../core/utils/folha_formatters.dart';
import '../../../../../core/widgets/folha_widgets.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../../shell/presentation/controllers/shell_controller.dart';
import '../controllers/transactions_controller.dart';

class TransactionsPage extends GetView<TransactionsController> {
  const TransactionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final searchOpen = false.obs;
    final searchCtrl = TextEditingController();
    final shell = Get.find<ShellController>();

    return Obx(() {
      final list = controller.filtered;
      final grouped = <String, List<TransactionEntity>>{};
      for (final t in list) {
        final k = FolhaFormatters.relativeDay(t.when);
        grouped.putIfAbsent(k, () => []).add(t);
      }
      final total = list.fold<double>(0, (a, b) => a + b.value);

      return SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 110),
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
                    onPressed: () => shell.goTo(0),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${FolhaFormatters.monthName(DateTime.now())} · ${list.length} MOVIMENTOS',
                          style: FolhaTypography.eyebrow.copyWith(
                            letterSpacing: 0.66,
                          ),
                        ),
                        Text(
                          'Movimentos',
                          style: FolhaTypography.titleEditorial(size: 24),
                        ),
                      ],
                    ),
                  ),
                  Obx(
                    () => FolhaIconBtn(
                      icon: searchOpen.value
                          ? LucideIcons.x
                          : LucideIcons.search,
                      variant: FolhaIconBtnVariant.soft,
                      onPressed: () {
                        searchOpen.value = !searchOpen.value;
                        if (!searchOpen.value) {
                          searchCtrl.clear();
                          controller.query.value = '';
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Search
            Obx(
              () => searchOpen.value
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                      child: FolhaInput(
                        controller: searchCtrl,
                        hintText: 'Buscar por descrição ou local',
                        autofocus: true,
                        onChanged: (v) => controller.query.value = v,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),

            // Total strip
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: FolhaColors.paper200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            controller.filter.value == 'income'
                                ? 'ENTRADAS'
                                : controller.filter.value == 'expense'
                                    ? 'SAÍDAS'
                                    : 'SALDO DO PERÍODO',
                            style: FolhaTypography.eyebrow.copyWith(
                              fontSize: 10,
                              letterSpacing: 0.6,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            FolhaFormatters.brl(total, sign: true),
                            style: FolhaTypography.currencyDisplay(
                              size: 22,
                              color: total < 0
                                  ? FolhaColors.terra700
                                  : FolhaColors.forest700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      LucideIcons.pieChart,
                      size: 28,
                      color: FolhaColors.ink400,
                    ),
                  ],
                ),
              ),
            ),

            // Filter chips
            const SizedBox(height: 12),
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _FilterPill(label: 'Tudo', id: 'all'),
                  const SizedBox(width: 8),
                  _FilterPill(
                    label: 'Entradas',
                    id: 'income',
                    dot: FolhaColors.forest500,
                  ),
                  const SizedBox(width: 8),
                  _FilterPill(
                    label: 'Saídas',
                    id: 'expense',
                    dot: FolhaColors.terra500,
                  ),
                  const SizedBox(width: 8),
                  VerticalDivider(
                    color: FolhaColors.divider,
                    width: 1,
                    indent: 8,
                    endIndent: 8,
                  ),
                  const SizedBox(width: 8),
                  ...FolhaCategoryStyles.all
                      .where((e) => e.key != 'income')
                      .map(
                        (e) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _FilterPill(
                            label: e.value.label,
                            id: e.key,
                            dot: e.value.color,
                          ),
                        ),
                      ),
                ],
              ),
            ),

            // Grouped list
            const SizedBox(height: 14),
            if (grouped.isEmpty)
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
                        size: 32,
                        color: FolhaColors.ink300,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Nada por aqui ainda.',
                        style: FolhaTypography.titleEditorial(
                          size: 17,
                          color: FolhaColors.ink700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tenta outro filtro.',
                        style: FolhaTypography.bodySm.copyWith(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...grouped.entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              entry.key.toUpperCase(),
                              style: FolhaTypography.eyebrow.copyWith(
                                letterSpacing: 1.1,
                              ),
                            ),
                            Text(
                              FolhaFormatters.brl(
                                entry.value.fold<double>(
                                  0,
                                  (a, b) => a + b.value,
                                ),
                                sign: true,
                              ),
                              style: FolhaTypography.currency(
                                size: 11,
                                color: FolhaColors.fgMuted,
                                weight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: FolhaColors.paper50,
                          border: Border.all(color: FolhaColors.border),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          children: List.generate(entry.value.length, (i) {
                            final t = entry.value[i];
                            return FolhaTxRow(
                              description: t.description,
                              place: t.place,
                              category: t.category,
                              value: t.value,
                              when: t.when,
                              divider: i < entry.value.length - 1,
                              onTap: () => Get.toNamed(
                                AppRoutes.transactionDetail,
                                arguments: t,
                              ),
                            );
                          }),
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

class _FilterPill extends GetView<TransactionsController> {
  final String label;
  final String id;
  final Color? dot;
  const _FilterPill({required this.label, required this.id, this.dot});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => FolhaPill(
        label: label,
        active: controller.filter.value == id,
        dot: dot,
        onTap: () => controller.filter.value = id,
      ),
    );
  }
}
