import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../../core/theme/folha_colors.dart';
import '../../../../../core/theme/folha_typography.dart';
import '../../../../../core/utils/folha_formatters.dart';
import '../../../../../core/widgets/folha_widgets.dart';
import '../controllers/transactions_controller.dart';

class AddTransactionSheet extends StatefulWidget {
  const AddTransactionSheet({super.key});

  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet> {
  String _type = 'expense';
  String _category = 'food';
  final _amount = TextEditingController();
  final _desc = TextEditingController();
  final _place = TextEditingController();

  double? _parsedAmount() {
    final v = _amount.text.replaceAll(',', '.');
    return double.tryParse(v);
  }

  bool get _valid =>
      _desc.text.trim().isNotEmpty && (_parsedAmount() ?? 0) > 0;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<TransactionsController>();
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
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
                  Text(
                    'Novo movimento',
                    style: FolhaTypography.titleEditorial(size: 24),
                  ),
                  FolhaIconBtn(
                    icon: LucideIcons.x,
                    variant: FolhaIconBtnVariant.soft,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Type switcher
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: FolhaColors.paper200,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  children: [
                    _TypeBtn(
                      id: 'expense',
                      label: 'Saída',
                      selected: _type,
                      onTap: () => setState(() => _type = 'expense'),
                    ),
                    _TypeBtn(
                      id: 'income',
                      label: 'Entrada',
                      selected: _type,
                      onTap: () => setState(() => _type = 'income'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // Big amount input
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
                        FilteringTextInputFormatter.allow(
                          RegExp(r'[\d,]'),
                        ),
                      ],
                      style: FolhaTypography.currencyDisplay(
                        size: 56,
                        style: FontStyle.italic,
                        color: _type == 'income'
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
                  hintText: 'Ex: Almoço com Júlia',
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(height: 12),
              FolhaField(
                label: 'Local (opcional)',
                child: FolhaInput(
                  controller: _place,
                  hintText: 'Ex: Tordesilhas',
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
                children: FolhaCategoryStyles.all
                    .where((e) => e.key != 'income')
                    .map((entry) {
                  final active = _category == entry.key;
                  final cat = entry.value;
                  return GestureDetector(
                    onTap: () => setState(() => _category = entry.key),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: active ? cat.bg : Colors.transparent,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: active ? cat.color : FolhaColors.border,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            cat.icon,
                            size: 14,
                            color: active ? cat.color : FolhaColors.ink700,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            cat.label,
                            style: FolhaTypography.body.copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: active
                                  ? cat.color
                                  : FolhaColors.ink700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: FolhaButton(
                      label: 'Cancelar',
                      variant: FolhaButtonVariant.ghost,
                      size: FolhaButtonSize.lg,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: FolhaButton(
                      label: 'Salvar movimento',
                      size: FolhaButtonSize.lg,
                      fullWidth: true,
                      onPressed: _valid
                          ? () async {
                              final parsed = _parsedAmount() ?? 0;
                              final signed =
                                  _type == 'income' ? parsed : -parsed;
                              final ok = await controller.add(
                                description: _desc.text.trim(),
                                place: _place.text.trim().isEmpty
                                    ? '—'
                                    : _place.text.trim(),
                                category: _category,
                                value: signed,
                              );
                              if (ok && context.mounted) {
                                Navigator.of(context).pop();
                                Get.snackbar(
                                  '',
                                  '',
                                  titleText: const SizedBox.shrink(),
                                  messageText: Text(
                                    '✓ Movimento salvo: ${_desc.text.trim()}',
                                    style: FolhaTypography.body.copyWith(
                                      color: FolhaColors.paper50,
                                      fontSize: 13,
                                    ),
                                  ),
                                  backgroundColor: FolhaColors.forest900,
                                  duration: const Duration(seconds: 2),
                                  margin: const EdgeInsets.fromLTRB(
                                    20,
                                    0,
                                    20,
                                    110,
                                  ),
                                  snackPosition: SnackPosition.BOTTOM,
                                );
                              }
                            }
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // formatador opcional - mostrar valor formatado
              if (_parsedAmount() != null && _parsedAmount()! > 0)
                Center(
                  child: Text(
                    FolhaFormatters.brl(
                      _type == 'income'
                          ? _parsedAmount()!
                          : -_parsedAmount()!,
                      sign: _type == 'income',
                    ),
                    style: FolhaTypography.bodySm.copyWith(fontSize: 11),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _TypeBtn extends StatelessWidget {
  final String id;
  final String label;
  final String selected;
  final VoidCallback onTap;

  const _TypeBtn({
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
            ? (id == 'income'
                ? FolhaColors.forest500
                : FolhaColors.forest700)
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
