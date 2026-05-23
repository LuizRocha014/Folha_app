import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../../../core/theme/folha_colors.dart';
import '../../../../../core/theme/folha_typography.dart';
import '../../../../../core/utils/folha_formatters.dart';
import '../../../../../core/widgets/folha_widgets.dart';
import '../../domain/entities/bill_entity.dart';
import '../controllers/bills_controller.dart';

/// Diálogo "Pagar valor parcial" — registra um pagamento que **subtrai** do
/// saldo restante da conta. Quando o saldo zera, a conta é promovida para
/// paid/received automaticamente.
class PartialPaymentDialog extends StatefulWidget {
  const PartialPaymentDialog({super.key, required this.bill});

  final BillEntity bill;

  @override
  State<PartialPaymentDialog> createState() => _PartialPaymentDialogState();
}

class _PartialPaymentDialogState extends State<PartialPaymentDialog> {
  final _amount = TextEditingController();
  bool _saving = false;

  double? get _parsed =>
      double.tryParse(_amount.text.replaceAll(',', '.'));

  bool get _valid =>
      (_parsed ?? 0) > 0 &&
      _parsed! <= widget.bill.remainingAmount + 0.005 &&
      !_saving;

  Future<void> _onConfirm() async {
    if (!_valid) return;
    setState(() => _saving = true);
    try {
      final controller = Get.find<BillsController>();
      final updated = await controller.payPartial(widget.bill.id, _parsed!);
      if (!mounted) return;
      if (updated != null) {
        Navigator.of(context).pop();
        final settled = updated.isSettled;
        Get.snackbar(
          '',
          '',
          titleText: const SizedBox.shrink(),
          messageText: Text(
            settled
                ? '✓ Conta quitada: ${widget.bill.description}'
                : '✓ Pagamento registrado · resta '
                  '${FolhaFormatters.brl(updated.remainingAmount)}',
            style: FolhaTypography.body.copyWith(
              color: FolhaColors.paper50,
              fontSize: 13,
            ),
          ),
          backgroundColor: FolhaColors.forest900,
          duration: const Duration(seconds: 3),
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 110),
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        final err = controller.error.value ?? 'Não foi possível registrar.';
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

  void _setQuickAmount(double v) {
    final clamped = v.clamp(0.01, widget.bill.remainingAmount);
    _amount.text = clamped.toStringAsFixed(2).replaceAll('.', ',');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final bill = widget.bill;
    final total = bill.amount.abs();
    final alreadyPaid = bill.paidAmount;
    final remaining = bill.remainingAmount;

    return Dialog(
      backgroundColor: FolhaColors.paper100,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pagar valor parcial',
              style: FolhaTypography.titleEditorial(size: 22),
            ),
            const SizedBox(height: 4),
            Text(
              bill.description,
              style: FolhaTypography.bodySm.copyWith(
                color: FolhaColors.fgMuted,
              ),
            ),
            const SizedBox(height: 14),
            // Resumo
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: FolhaColors.paper50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: FolhaColors.border),
              ),
              child: Column(
                children: [
                  _RowKV(
                    label: 'Valor total',
                    value: FolhaFormatters.brl(total),
                  ),
                  if (alreadyPaid > 0) ...[
                    const SizedBox(height: 4),
                    _RowKV(
                      label: 'Já pago',
                      value: FolhaFormatters.brl(alreadyPaid),
                      valueColor: FolhaColors.forest500,
                    ),
                  ],
                  const SizedBox(height: 4),
                  _RowKV(
                    label: 'Restante',
                    value: FolhaFormatters.brl(remaining),
                    valueColor: FolhaColors.ink900,
                    bold: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            FolhaField(
              label: 'Quanto você está pagando agora? (R\$)',
              child: FolhaInput(
                controller: _amount,
                hintText: '0,00',
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d,]')),
                ],
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _QuickChip(
                  label: '25%',
                  onTap: () => _setQuickAmount(remaining * 0.25),
                ),
                _QuickChip(
                  label: '50%',
                  onTap: () => _setQuickAmount(remaining * 0.5),
                ),
                _QuickChip(
                  label: '75%',
                  onTap: () => _setQuickAmount(remaining * 0.75),
                ),
                _QuickChip(
                  label: 'Restante',
                  onTap: () => _setQuickAmount(remaining),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if ((_parsed ?? 0) > 0)
              Text(
                _parsed! >= remaining - 0.005
                    ? 'Esse pagamento quita a conta.'
                    : 'Resta '
                      '${FolhaFormatters.brl(remaining - _parsed!)} '
                      'depois desse pagamento.',
                style: FolhaTypography.bodySm.copyWith(
                  fontSize: 12,
                  color: _parsed! >= remaining - 0.005
                      ? FolhaColors.forest700
                      : FolhaColors.fgMuted,
                ),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FolhaButton(
                    label: 'Cancelar',
                    variant: FolhaButtonVariant.ghost,
                    size: FolhaButtonSize.md,
                    onPressed:
                        _saving ? null : () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FolhaButton(
                    label: _saving ? 'Salvando...' : 'Pagar',
                    size: FolhaButtonSize.md,
                    loading: _saving,
                    onPressed: _valid ? _onConfirm : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RowKV extends StatelessWidget {
  const _RowKV({
    required this.label,
    required this.value,
    this.valueColor,
    this.bold = false,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: FolhaTypography.bodySm.copyWith(
            fontSize: 12,
            color: FolhaColors.fgMuted,
          ),
        ),
        Text(
          value,
          style: FolhaTypography.body.copyWith(
            fontSize: 13,
            fontWeight: bold ? FontWeight.w600 : FontWeight.w500,
            color: valueColor ?? FolhaColors.ink900,
          ),
        ),
      ],
    );
  }
}

class _QuickChip extends StatelessWidget {
  const _QuickChip({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: FolhaColors.paper50,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: FolhaColors.border),
        ),
        child: Text(
          label,
          style: FolhaTypography.body.copyWith(
            fontSize: 11,
            color: FolhaColors.ink700,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
