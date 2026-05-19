import 'package:flutter/material.dart';
import '../theme/folha_colors.dart';
import '../theme/folha_tokens.dart';
import '../theme/folha_typography.dart';

class FolhaPill extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback? onTap;
  final Color? dot;

  const FolhaPill({
    super.key,
    required this.label,
    this.active = false,
    this.onTap,
    this.dot,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? FolhaColors.forest700 : Colors.transparent,
      shape: StadiumBorder(
        side: BorderSide(
          color: active ? FolhaColors.forest700 : FolhaColors.ink200,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (dot != null) ...[
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: FolhaTypography.body.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: active ? FolhaColors.paper50 : FolhaColors.ink700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FolhaStatusPill extends StatelessWidget {
  final String status; // paid, pending, overdue, received
  const FolhaStatusPill({super.key, required this.status});

  ({String label, Color bg, Color fg}) get _map {
    switch (status) {
      case 'paid':
        return (label: 'PAGO', bg: FolhaColors.forest700, fg: FolhaColors.paper50);
      case 'overdue':
        return (
          label: 'VENCIDO',
          bg: FolhaColors.terra500,
          fg: FolhaColors.paper50,
        );
      case 'received':
        return (
          label: 'RECEBIDO',
          bg: FolhaColors.forest200,
          fg: FolhaColors.forest800,
        );
      default:
        return (
          label: 'PENDENTE',
          bg: FolhaColors.ocre500,
          fg: FolhaColors.forest900,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _map;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: s.bg,
        borderRadius: BorderRadius.circular(FolhaRadius.pill),
      ),
      child: Text(
        s.label,
        style: FolhaTypography.caption.copyWith(
          color: s.fg,
          letterSpacing: 0.5,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
