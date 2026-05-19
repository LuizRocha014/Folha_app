import 'package:flutter/material.dart';
import '../theme/folha_colors.dart';
import '../theme/folha_typography.dart';

class FolhaAvatar extends StatelessWidget {
  final String name;
  final double size;

  const FolhaAvatar({super.key, required this.name, this.size = 40});

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    final picks = parts.take(2).map((s) => s.isNotEmpty ? s[0] : '').join();
    return picks.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: FolhaColors.forest700,
        shape: BoxShape.circle,
        border: Border.all(color: FolhaColors.forest800, width: 1),
      ),
      alignment: Alignment.center,
      child: Text(
        _initials,
        style: FolhaTypography.titleEditorial(
          size: size * 0.42,
          color: FolhaColors.paper50,
        ),
      ),
    );
  }
}
