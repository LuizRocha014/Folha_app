import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../../core/routes/app_routes.dart';
import '../../../../../core/theme/folha_colors.dart';
import '../../../../../core/theme/folha_typography.dart';
import '../../../../../core/utils/folha_formatters.dart';
import '../../../../../core/widgets/folha_widgets.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../shell/presentation/controllers/shell_controller.dart';
import '../../../transactions/presentation/controllers/transactions_controller.dart';
import '../../../transactions/presentation/pages/add_transaction_sheet.dart';
import '../controllers/dashboard_controller.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    // O DashboardController é local da página — lazy put aqui.
    Get.lazyPut(() => DashboardController(), fenix: true);
    final dash = Get.find<DashboardController>();
    final txs = Get.find<TransactionsController>();
    final auth = Get.find<AuthController>();
    final shell = Get.find<ShellController>();

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
            child: Row(
              children: [
                Obx(
                  () => FolhaAvatar(
                    name: auth.user.value?.fullName ?? 'Marina Alves',
                    size: 42,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Obx(() {
                    final user = auth.user.value;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (user?.greeting() ?? 'Bom dia').toUpperCase(),
                          style: FolhaTypography.eyebrow,
                        ),
                        Text(
                          user?.firstName ?? 'Marina',
                          style: FolhaTypography.titleEditorial(size: 22),
                        ),
                      ],
                    );
                  }),
                ),
                FolhaIconBtn(
                  icon: LucideIcons.bell,
                  variant: FolhaIconBtnVariant.soft,
                  tooltip: 'Notificações',
                  onPressed: () {},
                ),
              ],
            ),
          ),

          // Hero balance
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: FolhaCard(
              dark: true,
              padding: 22,
              child: Stack(
                children: [
                  Positioned(
                    right: -40,
                    top: -30,
                    child: Opacity(
                      opacity: 0.08,
                      child: SvgPicture.asset(
                        'assets/svg/leaf-mark.svg',
                        width: 180,
                        height: 180,
                        colorFilter: const ColorFilter.mode(
                          FolhaColors.paper50,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'SALDO TOTAL',
                              style: FolhaTypography.eyebrow.copyWith(
                                color: FolhaColors.paper300,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ),
                          Obx(
                            () => GestureDetector(
                              onTap: dash.toggleBalance,
                              child: Icon(
                                dash.balanceHidden.value
                                    ? LucideIcons.eyeOff
                                    : LucideIcons.eye,
                                size: 18,
                                color: FolhaColors.paper300,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Obx(() {
                        // Recomputa quando a lista muda.
                        txs.items.length;
                        return FolhaCurrency(
                          value: txs.todayBalance,
                          big: true,
                          size: 54,
                          hidden: dash.balanceHidden.value,
                          color: FolhaColors.paper50,
                        );
                      }),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: FolhaColors.forest600,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              LucideIcons.trendingUp,
                              size: 13,
                              color: FolhaColors.forest300,
                            ),
                            const SizedBox(width: 4),
                            Obx(() {
                              // Recomputa quando a lista muda.
                              txs.items.length;
                              final delta = txs.weekDelta;
                              final sign = delta >= 0 ? '+' : '−';
                              return Text(
                                '$sign${FolhaFormatters.brl(delta.abs())} essa semana',
                                style: FolhaTypography.body.copyWith(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: FolhaColors.forest300,
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      Row(
                        children: [
                          _QuickAction(
                            icon: LucideIcons.arrowUp,
                            label: 'Enviar',
                            onTap: () => _openAddTransaction(context, 'expense'),
                          ),
                          const SizedBox(width: 10),
                          _QuickAction(
                            icon: LucideIcons.arrowDown,
                            label: 'Receber',
                            onTap: () => _openAddTransaction(context, 'income'),
                          ),
                          const SizedBox(width: 10),
                          _QuickAction(
                            icon: LucideIcons.creditCard,
                            label: 'Pagar',
                            onTap: () => shell.goTo(2),
                          ),
                          const SizedBox(width: 10),
                          _QuickAction(
                            icon: LucideIcons.moreHorizontal,
                            label: 'Mais',
                            onTap: () => _openMoreSheet(context),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Insight
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: FolhaColors.ocre100,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(
                    LucideIcons.sparkles,
                    size: 20,
                    color: FolhaColors.ocre700,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: FolhaTypography.body.copyWith(
                          fontSize: 13,
                          color: FolhaColors.ink700,
                          height: 1.4,
                        ),
                        children: [
                          const TextSpan(text: 'Você gastou '),
                          const TextSpan(
                            text: '12% menos',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: FolhaColors.ink900,
                            ),
                          ),
                          const TextSpan(
                            text: ' em alimentação esse mês. ',
                          ),
                          TextSpan(
                            text: 'Continua assim.',
                            style: FolhaTypography.titleEditorial(
                              size: 13,
                              color: FolhaColors.forest700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Weekly chart
          const SizedBox(height: 24),
          Obx(() {
            txs.items.length;
            final week = txs.last7DaysExpenses;
            final total = week.fold<double>(0, (a, b) => a + b.expense);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FolhaEyebrow(
                  label: 'Sua semana',
                  action: Text(
                    'Gasto: ${FolhaFormatters.brl(total)}',
                    style: FolhaTypography.body.copyWith(
                      fontSize: 12,
                      color: FolhaColors.forest700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
                    decoration: BoxDecoration(
                      color: FolhaColors.paper50,
                      border: Border.all(color: FolhaColors.border),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: _WeeklyChart(week: week),
                  ),
                ),
              ],
            );
          }),

          // Recent transactions
          const SizedBox(height: 24),
          FolhaEyebrow(
            label: 'Movimentos recentes',
            action: GestureDetector(
              onTap: () => shell.goTo(1),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Ver tudo',
                    style: FolhaTypography.body.copyWith(
                      fontSize: 12,
                      color: FolhaColors.forest700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Icon(
                    LucideIcons.chevronRight,
                    size: 14,
                    color: FolhaColors.forest700,
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            child: Obx(() {
              final recent = txs.items.take(4).toList();
              return Container(
                decoration: BoxDecoration(
                  color: FolhaColors.paper50,
                  border: Border.all(color: FolhaColors.border),
                  borderRadius: BorderRadius.circular(14),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: List.generate(recent.length, (i) {
                    final t = recent[i];
                    return FolhaTxRow(
                      description: t.description,
                      place: t.place,
                      category: t.category,
                      value: t.value,
                      when: t.when,
                      divider: i < recent.length - 1,
                      onTap: () => Get.toNamed(
                        AppRoutes.transactionDetail,
                        arguments: t,
                      ),
                    );
                  }),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

void _openAddTransaction(BuildContext context, String initialType) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: FolhaColors.forest900.withValues(alpha: 0.45),
    builder: (_) => AddTransactionSheet(initialType: initialType),
  );
}

void _openMoreSheet(BuildContext context) {
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
              _MoreTile(
                icon: LucideIcons.wallet,
                color: FolhaColors.forest700,
                title: 'Contas',
                onTap: () {
                  Navigator.of(sheetCtx).pop();
                  Get.toNamed(AppRoutes.accounts);
                },
              ),
              _MoreTile(
                icon: LucideIcons.creditCard,
                color: FolhaColors.ocre700,
                title: 'Cartões de crédito',
                onTap: () {
                  Navigator.of(sheetCtx).pop();
                  Get.toNamed(AppRoutes.creditCards);
                },
              ),
              _MoreTile(
                icon: LucideIcons.target,
                color: FolhaColors.forest500,
                title: 'Metas',
                onTap: () {
                  Navigator.of(sheetCtx).pop();
                  Get.toNamed(AppRoutes.goals);
                },
              ),
              _MoreTile(
                icon: LucideIcons.pieChart,
                color: FolhaColors.terra700,
                title: 'Orçamentos',
                onTap: () {
                  Navigator.of(sheetCtx).pop();
                  Get.toNamed(AppRoutes.budgets);
                },
              ),
              _MoreTile(
                icon: LucideIcons.bell,
                color: FolhaColors.ink700,
                title: 'Notificações',
                onTap: () {
                  Navigator.of(sheetCtx).pop();
                  Get.toNamed(AppRoutes.notifications);
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const _QuickAction({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: FolhaColors.paper50.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: FolhaColors.paper50),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: FolhaTypography.body.copyWith(
                    fontSize: 11,
                    color: FolhaColors.paper50,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MoreTile extends StatelessWidget {
  const _MoreTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
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
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: FolhaTypography.body.copyWith(fontSize: 14),
              ),
            ),
            const Icon(
              LucideIcons.chevronRight,
              size: 16,
              color: FolhaColors.fgMuted,
            ),
          ],
        ),
      ),
    );
  }
}

class _WeeklyChart extends StatefulWidget {
  final List<({String day, double expense})> week;
  const _WeeklyChart({required this.week});

  @override
  State<_WeeklyChart> createState() => _WeeklyChartState();
}

class _WeeklyChartState extends State<_WeeklyChart> {
  /// Índice selecionado pelo usuário (tap). `null` significa "nenhuma selecionada"
  /// — nesse caso o destaque automático fica em hoje (índice 6).
  int? _selected;

  static const _fullDayName = {
    'Dom': 'Domingo',
    'Seg': 'Segunda',
    'Ter': 'Terça',
    'Qua': 'Quarta',
    'Qui': 'Quinta',
    'Sex': 'Sexta',
    'Sáb': 'Sábado',
  };

  void _toggle(int i) {
    setState(() => _selected = _selected == i ? null : i);
  }

  @override
  Widget build(BuildContext context) {
    final dash = Get.find<DashboardController>();
    final week = widget.week;
    final maxVal = week.fold<double>(0, (m, w) => w.expense > m ? w.expense : m);
    // Hoje é o último item (índice 6) — week é ordenado cronologicamente.
    const todayIndex = 6;
    final activeIndex = _selected ?? todayIndex;
    final active = week[activeIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tooltip permanente do dia ativo: hoje quando nada tocado;
        // o dia tocado em destaque verde quando há seleção.
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 160),
          child: Container(
            key: ValueKey(activeIndex),
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _selected == null
                  ? FolhaColors.paper200
                  : FolhaColors.forest200,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _selected == null
                      ? LucideIcons.calendar
                      : LucideIcons.mousePointer2,
                  size: 12,
                  color: _selected == null
                      ? FolhaColors.fgMuted
                      : FolhaColors.forest700,
                ),
                const SizedBox(width: 6),
                Text(
                  '${_fullDayName[active.day] ?? active.day}: '
                  '${FolhaFormatters.brl(active.expense)}',
                  style: FolhaTypography.body.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _selected == null
                        ? FolhaColors.ink700
                        : FolhaColors.forest700,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(
          height: 120,
          child: Obx(() {
            final anim = dash.animateChart.value;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(week.length, (i) {
                final w = week[i];
                final isToday = i == todayIndex;
                final isSelected = _selected == i;
                final ratio = !anim || maxVal == 0 ? 0.0 : (w.expense / maxVal);

                final Color barColor;
                if (w.expense == 0) {
                  barColor = FolhaColors.paper200;
                } else if (isSelected) {
                  barColor = FolhaColors.forest500;
                } else if (isToday && _selected == null) {
                  barColor = FolhaColors.forest700;
                } else {
                  barColor = FolhaColors.forest300;
                }

                return Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _toggle(i),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: AnimatedContainer(
                                duration: Duration(milliseconds: 250 + i * 30),
                                curve: Curves.easeOutCubic,
                                // Reserva 2dp mínimos para barras zeradas — fica claro que tem dado.
                                height: (120 - 22) * ratio +
                                    (w.expense > 0 ? 0 : 2),
                                decoration: BoxDecoration(
                                  color: barColor,
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(6),
                                    bottom: Radius.circular(2),
                                  ),
                                  border: isSelected
                                      ? Border.all(
                                          color: FolhaColors.forest700,
                                          width: 1.5,
                                        )
                                      : null,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            w.day.toUpperCase(),
                            style: FolhaTypography.eyebrow.copyWith(
                              fontSize: 10,
                              color: isSelected
                                  ? FolhaColors.forest700
                                  : (isToday && _selected == null)
                                      ? FolhaColors.forest700
                                      : FolhaColors.fgMuted,
                              fontWeight: (isSelected ||
                                      (isToday && _selected == null))
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            );
          }),
        ),
      ],
    );
  }
}
