import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import '../../../../../core/database/local_database.dart';
import '../../../../../core/theme/folha_colors.dart';
import '../../../../../core/theme/folha_typography.dart';
import '../../../../../core/widgets/folha_widgets.dart';

/// Resultado retornado pelo `NewCategoryDialog`.
class NewCategoryResult {
  NewCategoryResult({
    required this.slug,
    required this.label,
    required this.icon,
    required this.color,
    required this.bg,
  });

  final String slug;
  final String label;
  final IconData icon;
  final Color color;
  final Color bg;
}

/// Dialog para o usuário criar uma categoria custom.
///
/// Grava em `categories` com `_sync_status = pending_create`. O CategorySyncer
/// hoje é read-only — quando o backend abrir endpoint de criação, basta
/// completar o `pushEntry`. Até lá a categoria vive 100% local.
class NewCategoryDialog extends StatefulWidget {
  const NewCategoryDialog({super.key});

  @override
  State<NewCategoryDialog> createState() => _NewCategoryDialogState();
}

class _NewCategoryDialogState extends State<NewCategoryDialog> {
  final _label = TextEditingController();
  int _iconIdx = 0;
  int _colorIdx = 0;
  bool _saving = false;

  static const _icons = [
    LucideIcons.tag,
    LucideIcons.coffee,
    LucideIcons.car,
    LucideIcons.book,
    LucideIcons.gift,
    LucideIcons.gamepad2,
    LucideIcons.shoppingBag,
    LucideIcons.heart,
    LucideIcons.briefcase,
    LucideIcons.plane,
  ];

  static const _palette = [
    (color: FolhaColors.forest700, bg: FolhaColors.forest200),
    (color: FolhaColors.terra700, bg: FolhaColors.terra100),
    (color: FolhaColors.ocre700, bg: FolhaColors.ocre100),
    (color: FolhaColors.ink700, bg: FolhaColors.paper200),
  ];

  bool get _valid => _label.text.trim().isNotEmpty && !_saving;

  Future<void> _save() async {
    if (!_valid) return;
    setState(() => _saving = true);
    try {
      final label = _label.text.trim();
      final slug = _slugify(label);
      final icon = _icons[_iconIdx];
      final colorEntry = _palette[_colorIdx];
      final now = DateTime.now().toUtc().toIso8601String();

      final db = Get.find<LocalDatabase>();
      await db.raw.insert(
        'categories',
        {
          'slug': slug,
          'server_id': null,
          'user_id': db.userId,
          'label': label,
          'icon': icon.codePoint.toString(),
          'color_hex': _hex(colorEntry.color),
          'bg_hex': _hex(colorEntry.bg),
          'kind': 'expense',
          'is_system': 0,
          'sort_order': 999,
          'created_at': now,
          'updated_at': now,
          '_sync_status': 'pending_create',
          '_local_updated_at': DateTime.now().millisecondsSinceEpoch,
          '_server_updated_at': null,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      if (!mounted) return;
      Navigator.of(context).pop(
        NewCategoryResult(
          slug: slug,
          label: label,
          icon: icon,
          color: colorEntry.color,
          bg: colorEntry.bg,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _slugify(String input) {
    final base = input
        .toLowerCase()
        .replaceAll(RegExp(r'[áàâãä]'), 'a')
        .replaceAll(RegExp(r'[éèêë]'), 'e')
        .replaceAll(RegExp(r'[íìîï]'), 'i')
        .replaceAll(RegExp(r'[óòôõö]'), 'o')
        .replaceAll(RegExp(r'[úùûü]'), 'u')
        .replaceAll(RegExp(r'ç'), 'c')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    final suffix = DateTime.now().millisecondsSinceEpoch
        .toString()
        .substring(8);
    return base.isEmpty ? 'cat_$suffix' : '${base}_$suffix';
  }

  String _hex(Color c) {
    final argb = c.toARGB32();
    return '#${argb.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
  }

  @override
  Widget build(BuildContext context) {
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
              'Nova categoria',
              style: FolhaTypography.titleEditorial(size: 22),
            ),
            const SizedBox(height: 4),
            Text(
              'Use pra agrupar gastos do seu jeito.',
              style: FolhaTypography.bodySm.copyWith(
                color: FolhaColors.fgMuted,
              ),
            ),
            const SizedBox(height: 16),
            FolhaField(
              label: 'Nome',
              child: FolhaInput(
                controller: _label,
                hintText: 'Ex: Pets, Educação, Streaming',
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'ÍCONE',
              style: FolhaTypography.eyebrow.copyWith(letterSpacing: 0.66),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(_icons.length, (i) {
                final active = _iconIdx == i;
                final palette = _palette[_colorIdx];
                return GestureDetector(
                  onTap: () => setState(() => _iconIdx = i),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: active ? palette.bg : FolhaColors.paper50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: active ? palette.color : FolhaColors.border,
                      ),
                    ),
                    child: Icon(
                      _icons[i],
                      size: 18,
                      color: active ? palette.color : FolhaColors.ink700,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 14),
            Text(
              'COR',
              style: FolhaTypography.eyebrow.copyWith(letterSpacing: 0.66),
            ),
            const SizedBox(height: 8),
            Row(
              children: List.generate(_palette.length, (i) {
                final p = _palette[i];
                final active = _colorIdx == i;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _colorIdx = i),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: p.bg,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: active ? p.color : FolhaColors.border,
                          width: active ? 2 : 1,
                        ),
                      ),
                      child: Icon(LucideIcons.check,
                          size: 18,
                          color: active ? p.color : Colors.transparent),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: FolhaButton(
                    label: 'Cancelar',
                    variant: FolhaButtonVariant.ghost,
                    size: FolhaButtonSize.md,
                    onPressed: _saving
                        ? null
                        : () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FolhaButton(
                    label: _saving ? 'Salvando...' : 'Criar',
                    size: FolhaButtonSize.md,
                    loading: _saving,
                    onPressed: _valid ? _save : null,
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
