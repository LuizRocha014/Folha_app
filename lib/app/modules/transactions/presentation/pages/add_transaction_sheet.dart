import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../../core/theme/folha_colors.dart';
import '../../../../../core/theme/folha_typography.dart';
import '../../../../../core/utils/folha_formatters.dart';
import '../../../../../core/widgets/folha_widgets.dart';
import '../../../categories/presentation/widgets/new_category_dialog.dart';
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
  bool _submitting = false;

  /// Categorias custom criadas em runtime pela função "Nova categoria".
  /// Persistem por sessão; o banco salva via `NewCategoryDialog`.
  final List<({String key, String label, IconData icon, Color color, Color bg})>
      _customCats = [];

  double? _parsedAmount() {
    final v = _amount.text.replaceAll(',', '.');
    return double.tryParse(v);
  }

  /// Para **entrada** só exige o valor; descrição é opcional.
  /// Para **saída** continua exigindo descrição + valor (evita lançamentos vagos).
  bool get _valid {
    if (_submitting) return false;
    if ((_parsedAmount() ?? 0) <= 0) return false;
    if (_type == 'income') return true;
    return _desc.text.trim().isNotEmpty;
  }

  /// Quando é entrada e o usuário não digita descrição, usamos um default
  /// neutro pra a transação não ficar com label vazio na listagem.
  String _resolvedDescription() {
    final typed = _desc.text.trim();
    if (typed.isNotEmpty) return typed;
    return _type == 'income' ? 'Entrada' : '';
  }

  Future<void> _onSave(TransactionsController controller) async {
    if (!_valid) return;
    setState(() => _submitting = true);
    try {
      final parsed = _parsedAmount() ?? 0;
      final signed = _type == 'income' ? parsed : -parsed;
      final desc = _resolvedDescription();
      final ok = await controller.add(
        description: desc,
        place: _place.text.trim().isEmpty ? '—' : _place.text.trim(),
        category: _category,
        value: signed,
      );
      if (!mounted) return;
      if (ok) {
        Navigator.of(context).pop();
        Get.snackbar(
          '',
          '',
          titleText: const SizedBox.shrink(),
          messageText: Text(
            '✓ Movimento salvo: $desc',
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
        final err = controller.error.value ?? 'Não consegui salvar o movimento.';
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
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _openNewCategoryDialog() async {
    final created = await showDialog<NewCategoryResult>(
      context: context,
      builder: (_) => const NewCategoryDialog(),
    );
    if (created == null) return;
    setState(() {
      _customCats.add((
        key: created.slug,
        label: created.label,
        icon: created.icon,
        color: created.color,
        bg: created.bg,
      ));
      _category = created.slug;
    });
  }

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
                  Expanded(
                    child: Text(
                      'Novo movimento',
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
                // Em entrada o título é opcional — o usuário sinaliza com o
                // sufixo no rótulo. Em saída continua obrigatório.
                label: _type == 'income' ? 'Descrição (opcional)' : 'Descrição',
                child: FolhaInput(
                  controller: _desc,
                  hintText: _type == 'income'
                      ? 'Ex: Salário, Bônus…'
                      : 'Ex: Almoço com Júlia',
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

              Row(
                children: [
                  Expanded(
                    child: Text(
                      'CATEGORIA',
                      style: FolhaTypography.eyebrow.copyWith(
                        letterSpacing: 0.66,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _openNewCategoryDialog,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          LucideIcons.plus,
                          size: 14,
                          color: FolhaColors.forest700,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Nova',
                          style: FolhaTypography.body.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: FolhaColors.forest700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ...FolhaCategoryStyles.all
                      .where((e) => e.key != 'income')
                      .map((entry) => _CategoryChip(
                            categoryKey: entry.key,
                            label: entry.value.label,
                            icon: entry.value.icon,
                            color: entry.value.color,
                            bg: entry.value.bg,
                            active: _category == entry.key,
                            onTap: () =>
                                setState(() => _category = entry.key),
                          )),
                  ..._customCats.map((c) => _CategoryChip(
                        categoryKey: c.key,
                        label: c.label,
                        icon: c.icon,
                        color: c.color,
                        bg: c.bg,
                        active: _category == c.key,
                        onTap: () => setState(() => _category = c.key),
                      )),
                ],
              ),

              const SizedBox(height: 22),
              // Botão principal em largura total + ação de cancelar discreta abaixo.
              // Mais espaço para o label longo "Salvar movimento" e zero overflow.
              FolhaButton(
                label: _submitting ? 'Salvando...' : 'Salvar movimento',
                size: FolhaButtonSize.lg,
                loading: _submitting,
                fullWidth: true,
                onPressed: _valid ? () => _onSave(controller) : null,
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: _submitting
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
              const SizedBox(height: 8),
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

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.categoryKey,
    required this.label,
    required this.icon,
    required this.color,
    required this.bg,
    required this.active,
    required this.onTap,
  });

  final String categoryKey;
  final String label;
  final IconData icon;
  final Color color;
  final Color bg;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: active ? bg : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: active ? color : FolhaColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: active ? color : FolhaColors.ink700),
            const SizedBox(width: 6),
            Text(
              label,
              style: FolhaTypography.body.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: active ? color : FolhaColors.ink700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
