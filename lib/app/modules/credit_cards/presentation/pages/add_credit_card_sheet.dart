import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../../core/theme/folha_colors.dart';
import '../../../../../core/theme/folha_typography.dart';
import '../../../../../core/widgets/folha_widgets.dart';
import '../controllers/credit_cards_controller.dart';

class AddCreditCardSheet extends StatefulWidget {
  const AddCreditCardSheet({super.key});

  @override
  State<AddCreditCardSheet> createState() => _AddCreditCardSheetState();
}

class _AddCreditCardSheetState extends State<AddCreditCardSheet> {
  final _name = TextEditingController();
  final _limit = TextEditingController();
  final _lastFour = TextEditingController();
  String _brand = 'visa';
  int _closingDay = 5;
  int _dueDay = 15;
  bool _saving = false;

  final List<_InstallmentDraft> _installments = [];

  @override
  void dispose() {
    _name.dispose();
    _limit.dispose();
    _lastFour.dispose();
    for (final d in _installments) {
      d.dispose();
    }
    super.dispose();
  }

  /// Converte os rascunhos preenchidos em entradas válidas para o controller.
  List<NewInstallmentInput> _collectInstallments() {
    final result = <NewInstallmentInput>[];
    for (final d in _installments) {
      final desc = d.description.text.trim();
      final total = int.tryParse(d.total.text.trim()) ?? 0;
      final paid = int.tryParse(d.paid.text.trim()) ?? 0;
      final amount = double.tryParse(
            d.amount.text.replaceAll('.', '').replaceAll(',', '.'),
          ) ??
          0;
      if (desc.isEmpty || total < 1 || amount <= 0) continue;
      final clampedPaid = paid < 0 ? 0 : (paid > total ? total : paid);
      result.add(NewInstallmentInput(
        description: desc,
        total: total,
        paid: clampedPaid,
        amount: amount,
      ));
    }
    return result;
  }

  static const _brands = ['visa', 'master', 'elo', 'amex', 'hiper', 'other'];

  static const _brandLabel = {
    'visa': 'Visa',
    'master': 'Mastercard',
    'elo': 'Elo',
    'amex': 'Amex',
    'hiper': 'Hipercard',
    'other': 'Outra',
  };

  double? get _parsedLimit =>
      double.tryParse(_limit.text.replaceAll('.', '').replaceAll(',', '.'));

  bool get _valid =>
      _name.text.trim().isNotEmpty && (_parsedLimit ?? 0) > 0 && !_saving;

  Future<void> _onSave() async {
    if (!_valid) return;
    setState(() => _saving = true);
    try {
      final controller = Get.find<CreditCardsController>();
      final ok = await controller.create(
        name: _name.text.trim(),
        brand: _brand,
        creditLimit: _parsedLimit!,
        closingDay: _closingDay,
        dueDay: _dueDay,
        lastFour: _lastFour.text.trim().isEmpty ? null : _lastFour.text.trim(),
        installments: _collectInstallments(),
      );
      if (!mounted) return;
      if (ok) {
        Navigator.of(context).pop();
        Get.snackbar(
          '',
          '',
          titleText: const SizedBox.shrink(),
          messageText: Text(
            '✓ Cartão salvo: ${_name.text.trim()}',
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
        final err = controller.error.value ?? 'Não consegui salvar o cartão.';
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
                      'Novo cartão',
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

              FolhaField(
                label: 'Nome do cartão',
                child: FolhaInput(
                  controller: _name,
                  hintText: 'Ex: Nubank Roxinho, Inter Black…',
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: FolhaField(
                      label: 'Limite (R\$)',
                      child: FolhaInput(
                        controller: _limit,
                        hintText: '0,00',
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
                        ],
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 1,
                    child: FolhaField(
                      label: '4 últimos',
                      child: FolhaInput(
                        controller: _lastFour,
                        hintText: '1234',
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(4),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                'BANDEIRA',
                style: FolhaTypography.eyebrow.copyWith(letterSpacing: 0.66),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _brands.map((b) {
                  final active = _brand == b;
                  return GestureDetector(
                    onTap: () => setState(() => _brand = b),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: active ? FolhaColors.forest200 : Colors.transparent,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: active ? FolhaColors.forest700 : FolhaColors.border,
                        ),
                      ),
                      child: Text(
                        _brandLabel[b]!,
                        style: FolhaTypography.body.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: active
                              ? FolhaColors.forest700
                              : FolhaColors.ink700,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _DayPicker(
                      label: 'FECHAMENTO',
                      value: _closingDay,
                      onChanged: (v) => setState(() => _closingDay = v),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DayPicker(
                      label: 'VENCIMENTO',
                      value: _dueDay,
                      onChanged: (v) => setState(() => _dueDay = v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              _InstallmentsSection(
                drafts: _installments,
                onAdd: () => setState(() => _installments.add(_InstallmentDraft())),
                onRemove: (d) => setState(() {
                  _installments.remove(d);
                  d.dispose();
                }),
                onChanged: () => setState(() {}),
              ),
              const SizedBox(height: 24),
              FolhaButton(
                label: _saving ? 'Salvando...' : 'Salvar cartão',
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

class _DayPicker extends StatelessWidget {
  const _DayPicker({
    required this.label,
    required this.value,
    required this.onChanged,
  });
  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: FolhaColors.paper50,
        border: Border.all(color: FolhaColors.border),
        borderRadius: BorderRadius.circular(12),
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
                onTap: () => onChanged(value > 1 ? value - 1 : 31),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    'dia $value',
                    style: FolhaTypography.body.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              _StepBtn(
                icon: LucideIcons.plus,
                onTap: () => onChanged(value < 31 ? value + 1 : 1),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepBtn extends StatelessWidget {
  const _StepBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: FolhaColors.paper100,
          shape: BoxShape.circle,
          border: Border.all(color: FolhaColors.border),
        ),
        child: Icon(icon, size: 14, color: FolhaColors.ink700),
      ),
    );
  }
}

/// Rascunho de um parcelamento sendo digitado no formulário.
class _InstallmentDraft {
  final TextEditingController description = TextEditingController();
  final TextEditingController total = TextEditingController();
  final TextEditingController paid = TextEditingController(text: '0');
  final TextEditingController amount = TextEditingController();

  void dispose() {
    description.dispose();
    total.dispose();
    paid.dispose();
    amount.dispose();
  }
}

/// Seção "Parcelamentos fixos" do cadastro de cartão. Cada parcelamento vira,
/// mês a mês, uma transação no cartão conforme as parcelas vencem.
class _InstallmentsSection extends StatelessWidget {
  const _InstallmentsSection({
    required this.drafts,
    required this.onAdd,
    required this.onRemove,
    required this.onChanged,
  });

  final List<_InstallmentDraft> drafts;
  final VoidCallback onAdd;
  final void Function(_InstallmentDraft) onRemove;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PARCELAMENTOS FIXOS',
          style: FolhaTypography.eyebrow.copyWith(letterSpacing: 0.66),
        ),
        const SizedBox(height: 4),
        Text(
          'Compras que já estão no cartão e entram na fatura todo mês até quitar. '
          'A parcela do mês vira uma transação automaticamente.',
          style: FolhaTypography.bodySm.copyWith(
            fontSize: 12,
            color: FolhaColors.fgMuted,
          ),
        ),
        const SizedBox(height: 10),
        ...drafts.asMap().entries.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _InstallmentCard(
                  index: e.key + 1,
                  draft: e.value,
                  onRemove: () => onRemove(e.value),
                  onChanged: onChanged,
                ),
              ),
            ),
        OutlinedButton.icon(
          onPressed: onAdd,
          icon: const Icon(LucideIcons.plus, size: 16),
          style: OutlinedButton.styleFrom(
            foregroundColor: FolhaColors.forest700,
            side: const BorderSide(color: FolhaColors.border),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          label: Text(
            'Adicionar parcelamento',
            style: FolhaTypography.body.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: FolhaColors.forest700,
            ),
          ),
        ),
      ],
    );
  }
}

class _InstallmentCard extends StatelessWidget {
  const _InstallmentCard({
    required this.index,
    required this.draft,
    required this.onRemove,
    required this.onChanged,
  });

  final int index;
  final _InstallmentDraft draft;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: FolhaColors.paper50,
        border: Border.all(color: FolhaColors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Parcelamento $index',
                  style: FolhaTypography.eyebrow.copyWith(
                    fontSize: 10,
                    letterSpacing: 0.66,
                  ),
                ),
              ),
              InkWell(
                onTap: onRemove,
                borderRadius: BorderRadius.circular(999),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(LucideIcons.trash2, size: 16, color: FolhaColors.terra700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          FolhaInput(
            controller: draft.description,
            hintText: 'Ex: Geladeira, Sofá…',
            onChanged: (_) => onChanged(),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _MiniField(
                  label: 'PARCELAS',
                  controller: draft.total,
                  hintText: '10',
                  digitsOnly: true,
                  onChanged: onChanged,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MiniField(
                  label: 'JÁ PAGAS',
                  controller: draft.paid,
                  hintText: '0',
                  digitsOnly: true,
                  onChanged: onChanged,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: _MiniField(
                  label: 'VALOR (R\$)',
                  controller: draft.amount,
                  hintText: '0,00',
                  digitsOnly: false,
                  onChanged: onChanged,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniField extends StatelessWidget {
  const _MiniField({
    required this.label,
    required this.controller,
    required this.hintText,
    required this.digitsOnly,
    required this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final String hintText;
  final bool digitsOnly;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: FolhaTypography.eyebrow.copyWith(letterSpacing: 0.5, fontSize: 9),
        ),
        const SizedBox(height: 4),
        FolhaInput(
          controller: controller,
          hintText: hintText,
          keyboardType: TextInputType.numberWithOptions(decimal: !digitsOnly),
          inputFormatters: digitsOnly
              ? [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(3),
                ]
              : [FilteringTextInputFormatter.allow(RegExp(r'[\d,.]'))],
          onChanged: (_) => onChanged(),
        ),
      ],
    );
  }
}
