import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../../core/routes/app_routes.dart';
import '../../../../../core/theme/folha_colors.dart';
import '../../../../../core/theme/folha_typography.dart';
import '../../../../../core/utils/folha_formatters.dart';
import '../../../../../core/widgets/folha_widgets.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../shell/presentation/controllers/shell_controller.dart';
import '../../../transactions/presentation/controllers/transactions_controller.dart';
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

    final week = const [
      ('Seg', 42.0),
      ('Ter', 87.0),
      ('Qua', 28.0),
      ('Qui', 156.0),
      ('Sex', 195.0),
      ('Sáb', 88.0),
      ('Dom', 51.0),
    ];

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
                      Obx(
                        () => FolhaCurrency(
                          value: txs.totals.balance,
                          big: true,
                          size: 54,
                          hidden: dash.balanceHidden.value,
                          color: FolhaColors.paper50,
                        ),
                      ),
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
                            Text(
                              '+${FolhaFormatters.brl(txs.weekDelta)} essa semana',
                              style: FolhaTypography.body.copyWith(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: FolhaColors.forest300,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      Row(
                        children: [
                          _QuickAction(
                            icon: LucideIcons.arrowUp,
                            label: 'Enviar',
                          ),
                          const SizedBox(width: 10),
                          _QuickAction(
                            icon: LucideIcons.arrowDown,
                            label: 'Receber',
                          ),
                          const SizedBox(width: 10),
                          _QuickAction(
                            icon: LucideIcons.creditCard,
                            label: 'Pagar',
                          ),
                          const SizedBox(width: 10),
                          _QuickAction(
                            icon: LucideIcons.moreHorizontal,
                            label: 'Mais',
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
          FolhaEyebrow(
            label: 'Sua semana',
            action: Text(
              'Total: ${FolhaFormatters.brl(week.map((w) => w.$2).reduce((a, b) => a + b))}',
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

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  const _QuickAction({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: FolhaColors.paper50.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
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
    );
  }
}

class _WeeklyChart extends StatelessWidget {
  final List<(String, double)> week;
  const _WeeklyChart({required this.week});

  @override
  Widget build(BuildContext context) {
    final dash = Get.find<DashboardController>();
    final maxVal = week.map((w) => w.$2).reduce((a, b) => a > b ? a : b);
    return SizedBox(
      height: 120,
      child: Obx(() {
        final anim = dash.animateChart.value;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(week.length, (i) {
            final w = week[i];
            final isToday = i == 4;
            final ratio = anim ? (w.$2 / maxVal) : 0.0;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 600 + i * 60),
                          curve: Curves.easeOutCubic,
                          height: (120 - 22) * ratio,
                          decoration: BoxDecoration(
                            color: isToday
                                ? FolhaColors.forest700
                                : FolhaColors.forest300,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(6),
                              bottom: Radius.circular(2),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      w.$1.toUpperCase(),
                      style: FolhaTypography.eyebrow.copyWith(
                        fontSize: 10,
                        color: isToday
                            ? FolhaColors.forest700
                            : FolhaColors.fgMuted,
                        fontWeight: isToday
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        );
      }),
    );
  }
}
