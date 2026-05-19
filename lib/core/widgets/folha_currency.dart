import 'package:flutter/material.dart';
import '../theme/folha_colors.dart';
import '../theme/folha_typography.dart';
import '../utils/folha_formatters.dart';

/// Currency com count-up animado (800ms ease-out cubic).
/// Quando `hidden=true`, renderiza "R$ ••••••".
class FolhaCurrency extends StatefulWidget {
  final double value;
  final bool sign;
  final bool big;
  final bool hidden;
  final Color? color;
  final double? size;

  const FolhaCurrency({
    super.key,
    required this.value,
    this.sign = false,
    this.big = false,
    this.hidden = false,
    this.color,
    this.size,
  });

  @override
  State<FolhaCurrency> createState() => _FolhaCurrencyState();
}

class _FolhaCurrencyState extends State<FolhaCurrency>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  double _previous = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _anim = Tween<double>(begin: 0, end: widget.value).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
    _ctrl.forward();
    _previous = widget.value;
  }

  @override
  void didUpdateWidget(covariant FolhaCurrency oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _anim = Tween<double>(begin: _previous, end: widget.value).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
      );
      _ctrl
        ..reset()
        ..forward();
      _previous = widget.value;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? FolhaColors.fg;
    final size = widget.size ?? (widget.big ? 48 : 15);

    if (widget.hidden) {
      return Text(
        'R\$ ••••••',
        style: widget.big
            ? FolhaTypography.currencyDisplay(size: size, color: color)
            : FolhaTypography.currency(size: size, color: color),
      );
    }

    return AnimatedBuilder(
      animation: _anim,
      builder: (_, child) {
        final formatted = FolhaFormatters.brl(_anim.value, sign: widget.sign);
        final parts = formatted.split(',');
        final main = parts[0];
        final cents = parts.length > 1 ? parts[1] : '00';

        final mainStyle = widget.big
            ? FolhaTypography.currencyDisplay(size: size, color: color)
            : FolhaTypography.currency(
                size: size,
                color: color,
                weight: FontWeight.w500,
              );
        final centsStyle = mainStyle.copyWith(
          fontSize: size * (widget.big ? 0.6 : 0.85),
          color: color.withValues(alpha: 0.6),
        );

        return RichText(
          text: TextSpan(
            text: main,
            style: mainStyle,
            children: [TextSpan(text: ',$cents', style: centsStyle)],
          ),
        );
      },
    );
  }
}
