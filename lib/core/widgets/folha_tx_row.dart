import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/folha_colors.dart';
import '../theme/folha_typography.dart';
import '../utils/folha_formatters.dart';

/// Categoria visual de uma transação.
class FolhaCategoryStyle {
  final String label;
  final IconData icon;
  final Color color;
  final Color bg;
  const FolhaCategoryStyle({
    required this.label,
    required this.icon,
    required this.color,
    required this.bg,
  });
}

class FolhaCategoryStyles {
  FolhaCategoryStyles._();

  static const Map<String, FolhaCategoryStyle> map = {
    'food': FolhaCategoryStyle(
      label: 'Alimentação',
      icon: LucideIcons.utensils,
      color: FolhaColors.forest700,
      bg: FolhaColors.forest200,
    ),
    'trans': FolhaCategoryStyle(
      label: 'Transporte',
      icon: LucideIcons.bus,
      color: FolhaColors.ocre700,
      bg: FolhaColors.ocre100,
    ),
    'leisure': FolhaCategoryStyle(
      label: 'Lazer',
      icon: LucideIcons.sparkles,
      color: FolhaColors.terra700,
      bg: FolhaColors.terra100,
    ),
    'home': FolhaCategoryStyle(
      label: 'Casa',
      icon: LucideIcons.home,
      color: FolhaColors.ink700,
      bg: FolhaColors.paper200,
    ),
    'health': FolhaCategoryStyle(
      label: 'Saúde',
      icon: LucideIcons.heart,
      color: FolhaColors.forest500,
      bg: FolhaColors.forest200,
    ),
    'shop': FolhaCategoryStyle(
      label: 'Compras',
      icon: LucideIcons.shoppingBag,
      color: FolhaColors.ink500,
      bg: FolhaColors.paper200,
    ),
    'income': FolhaCategoryStyle(
      label: 'Entrada',
      icon: LucideIcons.arrowDownCircle,
      color: FolhaColors.paper100,
      bg: FolhaColors.forest700,
    ),
    'other': FolhaCategoryStyle(
      label: 'Outros',
      icon: LucideIcons.circle,
      color: FolhaColors.ink500,
      bg: FolhaColors.paper200,
    ),
  };

  static FolhaCategoryStyle of(String id) => map[id] ?? map['other']!;
  static List<MapEntry<String, FolhaCategoryStyle>> get all =>
      map.entries.toList();
}

class FolhaTxRow extends StatelessWidget {
  final String description;
  final String place;
  final String category;
  final double value;
  final DateTime when;
  final bool divider;
  final VoidCallback? onTap;

  const FolhaTxRow({
    super.key,
    required this.description,
    required this.place,
    required this.category,
    required this.value,
    required this.when,
    this.divider = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cat = FolhaCategoryStyles.of(category);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: divider ? FolhaColors.divider : Colors.transparent,
              ),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: cat.bg,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(cat.icon, size: 18, color: cat.color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: FolhaTypography.body.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: FolhaColors.ink900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$place · ${FolhaFormatters.relativeDay(when)} · ${FolhaFormatters.time(when)}',
                      style: FolhaTypography.bodySm.copyWith(
                        fontSize: 11,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                FolhaFormatters.brl(value, sign: value > 0),
                style: FolhaTypography.currency(
                  size: 14,
                  weight: FontWeight.w500,
                  color: value > 0 ? FolhaColors.positive : FolhaColors.ink900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
