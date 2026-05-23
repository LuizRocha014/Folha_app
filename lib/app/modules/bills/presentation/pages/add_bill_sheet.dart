import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../../core/theme/folha_colors.dart';
import '../../../../../core/theme/folha_typography.dart';
import '../../../../../core/utils/folha_formatters.dart';
import '../../../../../core/widgets/folha_widgets.dart';
import '../controllers/bills_controller.dart';

/// Sheet de cadastro de conta fixa (a pagar ou a receber).
///
/// `initialKind` permite abrir o sheet já com o tipo certo quando o usuário
/// dispara do tab "A pagar" ou "A receber".
class AddBillSheet extends StatefulWidget {
  const AddBillSheet({super.key, this.initialKind = 'pay'});

  /// `'pay'` (default) ou `'receive'`.
  final String initialKind;

  @override
  State<AddBillSheet> createState() => _AddBillSheetState();
}

class _AddBillSheetState extends State<AddBillSheet> {
  /// 'pay' (conta a pagar) | 'receive' (a receber).
  late String _kind = widget.initialKind;
  String? _category = 'home';
  String? _recurrence; // 'monthly' | 'weekly' | 'yearly' | null
  DateTime _due = DateTime.now().add(const Duration(days: 7));

  final _desc = TextEditingController();
  final _amount = TextEditingController();
  final _notes = TextEditingController();

  /// Quando true, expõe campos de parcela atual/total.
  bool _hasInstallment = false;
  int _installmentCurrent = 1;
  int _installmentTotal = 12;

  bool _saving = false;

  static const _categoryOptions = <({String slug, String label, IconData icon})>[
    (slug: 'home', label: 'Moradia', icon: LucideIcons.home),
    (slug: 'food', label: 'Mercado', icon: LucideIcons.utensilsCrossed),
    (slug: 'trans', label: 'Transporte', icon: LucideIcons.car),
    (slug: 'health', label: 'Saúde', icon: LucideIcons.heartPulse),
    (slug: 'leisure', label: 'Lazer', icon: LucideIcons.smile),
    (slug: 'shop', label: 'Compras', icon: LucideIcons.shoppingBag),
    (slug: 'other', label: 'Outra', icon: LucideIcons.tag),
  ];

  static const _recurrenceOptions = <({String? id, String label})>[
    (id: null, label: 'Pontual'),
    (id: 'monthly', label: 'Mensal'),
    (id: 'weekly', label: 'Semanal'),
    (id: 'yearly', label: 'Anual'),
  ];

  double? get _parsedAmount =>
      double.tryParse(_amount.text.replaceAll(',', '.'));

  bool get _valid =>
      _desc.text.trim().isNotEmpty &&
      (_parsedAmount ?? 0) > 0 &&
      !_saving;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _due,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) setState(() => _due = picked);
  }

  Future<void> _onSave() async {
    if (!_valid) return;
    setState(() => _saving = true);
    try {
      final controller = Get.find<BillsController>();
      final ok = await controller.create(
        description: _desc.text.trim(),
        amount: _parsedAmount!,
        due: _due,
        isReceivable: _kind == 'receive',
        categorySlug: _category,
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        recurring: _recurrence,
        installmentCurrent: _hasInstallment ? _installmentCurrent : null,
        installmentTotal: _hasInstallment ? _installmentTotal : null,
      );
      if (!mounted) return;
      if (ok) {
        Navigator.of(context).pop();
        Get.snackbar(
          '',
          '',
          titleText: const SizedBox.shrink(),
          messageText: Text(
            '✓ Conta salva: ${_desc.text.trim()}',
            style: FolhaTypography.body.copyWith(
              color: FolhaColors.paper50,
              fontSize: 13,
            ),
          ),
          backgroundColor: FolhaColors.forest900,
          duration: const Duration(seconds: 2),
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 110),
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        final err = controller.error.value ?? 'Não consegui salvar a conta.';
        Get.snackbar(
          '',
          '',
          titleText: const SizedBox.shrink(),
          messageText: Text(
            err,
            style: FolhaTypography.body.copyWith(
              color: FolhaColors.paper50,
              fontSize: 13,
            ),
          ),
          backgroundColor: FolhaColors.terra700,
          duration: const Duration(seconds: 3),
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 110),
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.55,
      expand: false,
      builder: (_, scrollCtrl) {
        return Container(
          decoration: const BoxDecoration(
            color: FolhaColors.paper100,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 12,
            bottom: MediaQuery.of(context).viewInsets.bottom + 28,
          ),
          child: ListView(
            controller: scrollCtrl,
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
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Nova conta',
                      style: FolhaTypography.titleEditorial(size: 24),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  FolhaIconBtn(
                    icon: LucideIcons.x,
                    variant: FolhaIconBtnVariant.soft,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Pagar / Receber
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: FolhaColors.paper200,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  children: [
                    _KindBtn(
                      id: 'pay',
                      label: 'A pagar',
                      selected: _kind,
                      onTap: () => setState(() => _kind = 'pay'),
                    ),
                    _KindBtn(
                      id: 'receive',
                      label: 'A receber',
                      selected: _kind,
                      onTap: () => setState(() => _kind = 'receive'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // Valor
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(
                      'R\$',
                      style: FolhaTypography.body.copyWith(
                        fontSize: 18,
                        color: FolhaColors.fgMuted,
                      ),
                    ),
                  ),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 220),
                    child: TextField(
                      controller: _amount,
                      autofocus: true,
                      textAlign: TextAlign.center,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[\d,]')),
                      ],
                      style: FolhaTypography.currencyDisplay(
                        size: 56,
                        style: FontStyle.italic,
                        color: _kind == 'receive'
                            ? FolhaColors.forest500
                            : FolhaColors.ink900,
                      ),
                      cursorColor: FolhaColors.forest700,
                      decoration: const InputDecoration(
                        hintText: '0,00',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              FolhaField(
                label: 'Descrição',
                child: FolhaInput(
                  controller: _desc,
                  hintText: 'Ex: Aluguel, Internet, Mensalidade…',
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(height: 12),

              // Data de vencimento
              FolhaField(
                label: _kind == 'pay' ? 'Vencimento' : 'Recebimento previsto',
                child: InkWell(
                  onTap: _pickDate,
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
                        const Icon(
                          LucideIcons.calendar,
                          size: 18,
                          color: FolhaColors.ink700,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${FolhaFormatters.relativeDay(_due)} · '
                            '${_due.day.toString().padLeft(2, '0')}/'
                            '${_due.month.toString().padLeft(2, '0')}/'
                            '${_due.year}',
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
                ),
              ),
              const SizedBox(height: 14),

              Text(
                'CATEGORIA',
                style: FolhaTypography.eyebrow.copyWith(letterSpacing: 0.66),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _categoryOptions.map((c) {
                  final active = _category == c.slug;
                  return GestureDetector(
                    onTap: () => setState(() => _category = c.slug),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: active ? FolhaColors.forest200 : Colors.transparent,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: active ? FolhaColors.forest700 : FolhaColors.border,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            c.icon,
                            size: 14,
                            color: active ? FolhaColors.forest700 : FolhaColors.ink700,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            c.label,
                            style: FolhaTypography.body.copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: active
                                  ? FolhaColors.forest700
                                  : FolhaColors.ink700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),

              // Parcelas (opcional) — útil para boletos parcelados, financiamentos, etc.
              InkWell(
                onTap: () => setState(() => _hasInstallment = !_hasInstallment),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(
                        _hasInstallment
                            ? LucideIcons.squareCheckBig
                            : LucideIcons.square,
                        size: 20,
                        color: _hasInstallment
                            ? FolhaColors.forest700
                            : FolhaColors.ink400,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'É uma parcela',
                          style: FolhaTypography.body.copyWith(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_hasInstallment) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  decoration: BoxDecoration(
                    color: FolhaColors.ocre100.withValues(alpha: 0.5),
                    border: Border.all(color: FolhaColors.ocre100),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CONTROLE DE PARCELAS',
                        style: FolhaTypography.eyebrow.copyWith(
                          letterSpacing: 0.66,
                          color: FolhaColors.ocre700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Anota qual parcela esta conta representa para você '
                        'acompanhar quantas faltam.',
                        style: FolhaTypography.bodySm.copyWith(
                          fontSize: 12,
                          color: FolhaColors.ink700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _InstallmentStepper(
                              label: 'PARCELA ATUAL',
                              value: _installmentCurrent,
                              max: _installmentTotal,
                              onChanged: (v) =>
                                  setState(() => _installmentCurrent = v),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _InstallmentStepper(
                              label: 'TOTAL',
                              value: _installmentTotal,
                              max: 240,
                              min: _installmentCurrent,
                              onChanged: (v) =>
                                  setState(() => _installmentTotal = v),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],
              Text(
                'RECORRÊNCIA',
                style: FolhaTypography.eyebrow.copyWith(letterSpacing: 0.66),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _recurrenceOptions.map((r) {
                  final active = _recurrence == r.id;
                  return GestureDetector(
                    onTap: () => setState(() => _recurrence = r.id),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: active ? FolhaColors.ocre100 : Colors.transparent,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: active ? FolhaColors.ocre700 : FolhaColors.border,
                        ),
                      ),
                      child: Text(
                        r.label,
                        style: FolhaTypography.body.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: active ? FolhaColors.ocre700 : FolhaColors.ink700,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              FolhaField(
                label: 'Anotação (opcional)',
                child: FolhaInput(
                  controller: _notes,
                  hintText: 'Ex: vence todo dia 5',
                ),
              ),

              const SizedBox(height: 22),
              FolhaButton(
                label: _saving ? 'Salvando...' : 'Salvar conta',
                size: FolhaButtonSize.lg,
                loading: _saving,
                fullWidth: true,
                onPressed: _valid ? _onSave : null,
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: _saving
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: Text(
                    'Cancelar',
                    style: FolhaTypography.body.copyWith(
                      fontSize: 13,
                      color: FolhaColors.fgMuted,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _KindBtn extends StatelessWidget {
  final String id;
  final String label;
  final String selected;
  final VoidCallback onTap;
  const _KindBtn({
    required this.id,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final active = selected == id;
    return Expanded(
      child: Material(
        color: active
            ? (id == 'receive' ? FolhaColors.forest500 : FolhaColors.forest700)
            : Colors.transparent,
        shape: const StadiumBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const StadiumBorder(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Center(
              child: Text(
                label,
                style: FolhaTypography.body.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: active ? FolhaColors.paper50 : FolhaColors.fgMuted,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InstallmentStepper extends StatelessWidget {
  const _InstallmentStepper({
    required this.label,
    required this.value,
    required this.onChanged,
    this.min = 1,
    this.max = 99,
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: FolhaColors.paper50,
        border: Border.all(color: FolhaColors.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: FolhaTypography.eyebrow.copyWith(
              letterSpacing: 0.66,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _StepBtn(
                icon: LucideIcons.minus,
                enabled: value > min,
                onTap: () => onChanged(value - 1),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    '$value',
                    style: FolhaTypography.body.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              _StepBtn(
                icon: LucideIcons.plus,
                enabled: value < max,
                onTap: () => onChanged(value + 1),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepBtn extends StatelessWidget {
  const _StepBtn({
    required this.icon,
    required this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.3,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: FolhaColors.paper100,
            shape: BoxShape.circle,
            border: Border.all(color: FolhaColors.border),
          ),
          child: Icon(icon, size: 13, color: FolhaColors.ink700),
        ),
      ),
    );
  }
}
