import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../../core/database/local_database.dart';
import '../../../../../core/theme/folha_colors.dart';
import '../../../../../core/theme/folha_typography.dart';
import '../../../../../core/utils/folha_formatters.dart';

class BudgetsPage extends StatefulWidget {
  const BudgetsPage({super.key});

  @override
  State<BudgetsPage> createState() => _BudgetsPageState();
}

class _BudgetsPageState extends State<BudgetsPage> {
  List<Map<String, dynamic>> _budgets = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final db = Get.find<LocalDatabase>();
    final rows = await db.raw.query(
      'budgets',
      where: 'user_id = ?',
      whereArgs: [db.userId],
      orderBy: 'reference_month DESC',
    );
    if (!mounted) return;
    setState(() {
      _budgets = rows;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final monthFmt = DateFormat('MMMM yyyy', 'pt_BR');
    return Scaffold(
      backgroundColor: FolhaColors.paper100,
      appBar: AppBar(
        backgroundColor: FolhaColors.paper100,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, color: FolhaColors.ink900),
          onPressed: Get.back,
        ),
        title: Text('Orçamentos', style: FolhaTypography.titleEditorial(size: 22)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _budgets.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.pieChart, size: 56, color: FolhaColors.ink400),
                        const SizedBox(height: 16),
                        Text(
                          'Sem orçamentos.',
                          style: FolhaTypography.titleEditorial(size: 20),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Defina limites mensais por categoria pra acompanhar seus gastos.',
                          textAlign: TextAlign.center,
                          style: FolhaTypography.bodySm.copyWith(color: FolhaColors.fgMuted),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                    itemCount: _budgets.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final b = _budgets[i];
                      final month = DateTime.tryParse(b['reference_month'] as String) ?? DateTime.now();
                      final limit = ((b['amount_limit'] as num?) ?? 0).toDouble();
                      final threshold = (b['alert_threshold'] as int?) ?? 80;
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: FolhaColors.paper50,
                          border: Border.all(color: FolhaColors.border),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: FolhaColors.forest200,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(LucideIcons.pieChart, size: 18, color: FolhaColors.forest700),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    monthFmt.format(month).toUpperCase(),
                                    style: FolhaTypography.eyebrow.copyWith(letterSpacing: 0.66, fontSize: 11),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Categoria ${b['category_slug']}',
                                    style: FolhaTypography.body.copyWith(fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  FolhaFormatters.brl(limit),
                                  style: FolhaTypography.body.copyWith(fontWeight: FontWeight.w500),
                                ),
                                Text(
                                  'alerta em $threshold%',
                                  style: FolhaTypography.bodySm.copyWith(fontSize: 11, color: FolhaColors.fgMuted),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
