import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../../core/theme/folha_colors.dart';
import '../../../../../core/theme/folha_typography.dart';
import '../../../../../core/utils/folha_formatters.dart';
import '../../../../../core/widgets/folha_widgets.dart';
import '../../domain/entities/goal_entity.dart';
import '../controllers/goals_controller.dart';

class GoalsPage extends StatelessWidget {
  const GoalsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<GoalsController>();
    return Scaffold(
      backgroundColor: FolhaColors.paper100,
      appBar: AppBar(
        backgroundColor: FolhaColors.paper100,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, color: FolhaColors.ink900),
          onPressed: Get.back,
        ),
        title: Text('Metas', style: FolhaTypography.titleEditorial(size: 22)),
      ),
      body: Obx(() {
        if (ctrl.loading.value && ctrl.items.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (ctrl.items.isEmpty) {
          return _EmptyState(onAdd: () => _showCreateSheet(context, ctrl));
        }
        return RefreshIndicator(
          onRefresh: ctrl.refreshList,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
            itemCount: ctrl.items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _GoalCard(goal: ctrl.items[i]),
          ),
        );
      }),
      floatingActionButton: FloatingActionButton(
        backgroundColor: FolhaColors.forest700,
        foregroundColor: FolhaColors.paper50,
        onPressed: () => _showCreateSheet(context, Get.find<GoalsController>()),
        child: const Icon(LucideIcons.plus),
      ),
    );
  }

  void _showCreateSheet(BuildContext context, GoalsController ctrl) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: FolhaColors.paper100,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _CreateGoalSheet(controller: ctrl),
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({required this.goal});
  final GoalEntity goal;

  @override
  Widget build(BuildContext context) {
    final pct = (goal.progress * 100).round();
    final yield_ = goal.estimatedMonthlyYield;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FolhaColors.paper50,
        border: Border.all(color: FolhaColors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: FolhaColors.forest200,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Icon(LucideIcons.target, size: 18, color: FolhaColors.forest700),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  goal.title,
                  style: FolhaTypography.titleEditorial(size: 18),
                ),
              ),
              if (goal.isCompleted)
                const Icon(LucideIcons.checkCircle2, color: FolhaColors.forest500, size: 18),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                FolhaFormatters.brl(goal.currentAmount),
                style: FolhaTypography.body.copyWith(fontWeight: FontWeight.w500),
              ),
              Text(
                'de ${FolhaFormatters.brl(goal.targetAmount)}',
                style: FolhaTypography.bodySm.copyWith(color: FolhaColors.fgMuted),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: goal.progress,
              minHeight: 8,
              backgroundColor: FolhaColors.paper200,
              valueColor: const AlwaysStoppedAnimation(FolhaColors.forest500),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$pct%', style: FolhaTypography.bodySm.copyWith(fontSize: 12)),
              if (goal.daysLeft != null)
                Text(
                  goal.daysLeft! < 0
                      ? '${-goal.daysLeft!} dias em atraso'
                      : '${goal.daysLeft} dias restantes',
                  style: FolhaTypography.bodySm.copyWith(fontSize: 12, color: FolhaColors.fgMuted),
                ),
            ],
          ),
          if (goal.monthlyYieldPercent != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: FolhaColors.ocre100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(
                    LucideIcons.trendingUp,
                    size: 16,
                    color: FolhaColors.ocre700,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Rende ${goal.monthlyYieldPercent!.toStringAsFixed(2).replaceAll('.', ',')}% ao mês',
                              style: FolhaTypography.body.copyWith(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: FolhaColors.ocre700,
                              ),
                            ),
                            if (goal.isCdb) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: FolhaColors.forest700,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'CDB',
                                  style: FolhaTypography.eyebrow.copyWith(
                                    fontSize: 9,
                                    color: FolhaColors.paper50,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (yield_ != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            '≈ ${FolhaFormatters.brl(yield_)} no próximo mês',
                            style: FolhaTypography.bodySm.copyWith(
                              fontSize: 11,
                              color: FolhaColors.ink700,
                            ),
                          ),
                        ] else
                          Text(
                            'Adicione valor à meta para projetar o rendimento.',
                            style: FolhaTypography.bodySm.copyWith(
                              fontSize: 11,
                              color: FolhaColors.fgMuted,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.target, size: 56, color: FolhaColors.ink400),
          const SizedBox(height: 16),
          Text('Você não tem metas ainda.', style: FolhaTypography.titleEditorial(size: 22)),
          const SizedBox(height: 6),
          Text(
            'Defina objetivos — viagem, reserva, sonho — e acompanhe o progresso.',
            textAlign: TextAlign.center,
            style: FolhaTypography.bodySm.copyWith(color: FolhaColors.fgMuted),
          ),
          const SizedBox(height: 20),
          FolhaButton(label: 'Criar meta', size: FolhaButtonSize.md, onPressed: onAdd),
        ],
      ),
    );
  }
}

class _CreateGoalSheet extends StatefulWidget {
  const _CreateGoalSheet({required this.controller});
  final GoalsController controller;

  @override
  State<_CreateGoalSheet> createState() => _CreateGoalSheetState();
}

class _CreateGoalSheetState extends State<_CreateGoalSheet> {
  final _title = TextEditingController();
  final _target = TextEditingController();
  final _desc = TextEditingController();
  final _yield = TextEditingController();
  DateTime? _targetDate;
  bool _isCdb = false;
  bool _saving = false;

  double? _parsedTarget() =>
      double.tryParse(_target.text.replaceAll(',', '.'));
  double? _parsedYield() =>
      double.tryParse(_yield.text.replaceAll(',', '.'));

  bool get _valid =>
      _title.text.trim().isNotEmpty &&
      (_parsedTarget() ?? 0) > 0 &&
      !_saving;

  Future<void> _onSave() async {
    if (!_valid) return;
    setState(() => _saving = true);
    try {
      final ok = await widget.controller.create(
        title: _title.text.trim(),
        targetAmount: _parsedTarget()!,
        description: _desc.text.trim().isEmpty ? null : _desc.text.trim(),
        targetDate: _targetDate,
        monthlyYieldPercent: _parsedYield(),
        isCdb: _isCdb,
      );
      if (!mounted) return;
      if (ok) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 18,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: FolhaColors.ink200,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Nova meta', style: FolhaTypography.titleEditorial(size: 22)),
            ),
            const SizedBox(height: 16),
            FolhaField(
              label: 'Título',
              child: FolhaInput(
                controller: _title,
                hintText: 'Ex: Viagem pra Bahia',
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(height: 12),
            FolhaField(
              label: 'Valor alvo (R\$)',
              child: FolhaInput(
                controller: _target,
                hintText: '0,00',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d,]')),
                ],
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(height: 12),
            FolhaField(
              label: 'Descrição (opcional)',
              child: FolhaInput(controller: _desc, hintText: '…'),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () async {
                final now = DateTime.now();
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _targetDate ?? now.add(const Duration(days: 30)),
                  firstDate: now,
                  lastDate: now.add(const Duration(days: 365 * 5)),
                );
                if (picked != null) setState(() => _targetDate = picked);
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: FolhaColors.paper50,
                  border: Border.all(color: FolhaColors.border),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.calendar, size: 18, color: FolhaColors.ink700),
                    const SizedBox(width: 10),
                    Text(
                      _targetDate == null
                          ? 'Data limite (opcional)'
                          : 'Em ${_targetDate!.day}/${_targetDate!.month}/${_targetDate!.year}',
                      style: FolhaTypography.body.copyWith(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            // Bloco "Está rendendo?" — campos opcionais de rendimento
            Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              decoration: BoxDecoration(
                color: FolhaColors.ocre100.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: FolhaColors.ocre100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        LucideIcons.trendingUp,
                        size: 16,
                        color: FolhaColors.ocre700,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'ESTÁ RENDENDO?',
                        style: FolhaTypography.eyebrow.copyWith(
                          letterSpacing: 0.66,
                          color: FolhaColors.ocre700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Se a sua poupança ou aplicação rende uma % por mês, '
                    'a Folha projeta o ganho.',
                    style: FolhaTypography.bodySm.copyWith(
                      fontSize: 12,
                      color: FolhaColors.ink700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FolhaField(
                    label: '% ao mês',
                    child: FolhaInput(
                      controller: _yield,
                      hintText: 'Ex: 0,80',
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[\d,]')),
                      ],
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: () => setState(() => _isCdb = !_isCdb),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Icon(
                            _isCdb
                                ? LucideIcons.squareCheckBig
                                : LucideIcons.square,
                            size: 20,
                            color: _isCdb
                                ? FolhaColors.forest700
                                : FolhaColors.ink400,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Está rendendo via CDB',
                              style: FolhaTypography.body.copyWith(
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_parsedYield() != null &&
                      (_parsedYield() ?? 0) > 0 &&
                      (_parsedTarget() ?? 0) > 0) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: FolhaColors.paper50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        // Mostra a projeção sobre o valor alvo (best case),
                        // só para o usuário ter referência antes de guardar valor.
                        'Projeção sobre o alvo: '
                        '${FolhaFormatters.brl(_parsedTarget()! * (_parsedYield()! / 100))}'
                        ' / mês',
                        style: FolhaTypography.bodySm.copyWith(
                          fontSize: 11,
                          color: FolhaColors.ink700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            FolhaButton(
              label: _saving ? 'Salvando...' : 'Criar meta',
              size: FolhaButtonSize.lg,
              fullWidth: true,
              loading: _saving,
              onPressed: _valid ? _onSave : null,
            ),
          ],
        ),
      ),
    );
  }
}
