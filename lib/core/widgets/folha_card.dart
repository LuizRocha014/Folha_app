import 'package:flutter/material.dart';
import '../theme/folha_colors.dart';
import '../theme/folha_tokens.dart';

class FolhaCard extends StatelessWidget {
  final Widget child;
  final bool dark;
  final double padding;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? margin;

  const FolhaCard({
    super.key,
    required this.child,
    this.dark = false,
    this.padding = 18,
    this.onTap,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final inner = Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: dark ? FolhaColors.forest900 : FolhaColors.paper50,
        border: dark ? null : Border.all(color: FolhaColors.border, width: 1),
        borderRadius: BorderRadius.circular(FolhaRadius.lg),
      ),
      child: DefaultTextStyle.merge(
        style: TextStyle(color: dark ? FolhaColors.paper50 : FolhaColors.fg),
        child: child,
      ),
    );

    final wrapped = onTap == null
        ? inner
        : Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(FolhaRadius.lg),
              child: inner,
            ),
          );

    return margin == null ? wrapped : Padding(padding: margin!, child: wrapped);
  }
}
