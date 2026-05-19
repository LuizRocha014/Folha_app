import 'package:flutter/material.dart';
import '../theme/folha_typography.dart';

class FolhaHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? leadAction;
  final Widget? trailAction;

  const FolhaHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.leadAction,
    this.trailAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Row(
        children: [
          if (leadAction != null) ...[leadAction!, const SizedBox(width: 12)],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (subtitle != null)
                  Text(
                    subtitle!.toUpperCase(),
                    style: FolhaTypography.eyebrow,
                  ),
                Padding(
                  padding: EdgeInsets.only(top: subtitle != null ? 2 : 0),
                  child: Text(
                    title,
                    style: FolhaTypography.titleEditorial(size: 28),
                  ),
                ),
              ],
            ),
          ),
          if (trailAction != null) ...[const SizedBox(width: 12), trailAction!],
        ],
      ),
    );
  }
}

class FolhaEyebrow extends StatelessWidget {
  final String label;
  final Widget? action;
  final EdgeInsets padding;

  const FolhaEyebrow({
    super.key,
    required this.label,
    this.action,
    this.padding = const EdgeInsets.symmetric(horizontal: 20),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label.toUpperCase(),
            style: FolhaTypography.eyebrow.copyWith(letterSpacing: 1.1),
          ),
          ?action,
        ],
      ),
    );
  }
}

class FolhaBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color bg;
  final bool small;
  const FolhaBadge({
    super.key,
    required this.label,
    required this.color,
    required this.bg,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 8 : 10,
        vertical: small ? 2 : 3,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: FolhaTypography.body.copyWith(
              fontSize: small ? 11 : 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
