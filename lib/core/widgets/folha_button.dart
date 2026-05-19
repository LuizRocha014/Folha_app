import 'package:flutter/material.dart';
import '../theme/folha_colors.dart';
import '../theme/folha_tokens.dart';
import '../theme/folha_typography.dart';

enum FolhaButtonVariant { primary, accent, secondary, ghost, danger }

enum FolhaButtonSize { sm, md, lg }

class FolhaButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final FolhaButtonVariant variant;
  final FolhaButtonSize size;
  final IconData? leadIcon;
  final bool fullWidth;
  final bool loading;

  const FolhaButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = FolhaButtonVariant.primary,
    this.size = FolhaButtonSize.md,
    this.leadIcon,
    this.fullWidth = false,
    this.loading = false,
  });

  @override
  State<FolhaButton> createState() => _FolhaButtonState();
}

class _FolhaButtonState extends State<FolhaButton> {
  bool _pressed = false;

  ({EdgeInsets pad, double fs}) get _sizes => switch (widget.size) {
    FolhaButtonSize.sm => (
      pad: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      fs: 13,
    ),
    FolhaButtonSize.md => (
      pad: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
      fs: 14,
    ),
    FolhaButtonSize.lg => (
      pad: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
      fs: 15,
    ),
  };

  ({Color bg, Color fg, Color br}) get _variant => switch (widget.variant) {
    FolhaButtonVariant.primary => (
      bg: FolhaColors.forest700,
      fg: FolhaColors.paper50,
      br: Colors.transparent,
    ),
    FolhaButtonVariant.accent => (
      bg: FolhaColors.ocre500,
      fg: FolhaColors.forest900,
      br: Colors.transparent,
    ),
    FolhaButtonVariant.secondary => (
      bg: Colors.transparent,
      fg: FolhaColors.forest700,
      br: FolhaColors.forest700,
    ),
    FolhaButtonVariant.ghost => (
      bg: Colors.transparent,
      fg: FolhaColors.forest700,
      br: Colors.transparent,
    ),
    FolhaButtonVariant.danger => (
      bg: Colors.transparent,
      fg: FolhaColors.terra500,
      br: FolhaColors.terra300,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final s = _sizes;
    final v = _variant;
    final disabled = widget.onPressed == null || widget.loading;

    final child = AnimatedScale(
      scale: _pressed ? 0.97 : 1,
      duration: FolhaDuration.fast,
      curve: Curves.easeOut,
      child: Container(
        padding: s.pad,
        decoration: BoxDecoration(
          color: v.bg,
          border: Border.all(color: v.br, width: 1),
          borderRadius: BorderRadius.circular(FolhaRadius.pill),
        ),
        child: Row(
          mainAxisSize: widget.fullWidth ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.loading)
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(v.fg),
                ),
              )
            else if (widget.leadIcon != null) ...[
              Icon(widget.leadIcon, size: 16, color: v.fg),
              const SizedBox(width: 8),
            ],
            if (!widget.loading)
              Text(
                widget.label,
                style: FolhaTypography.body.copyWith(
                  fontSize: s.fs,
                  fontWeight: FontWeight.w500,
                  color: v.fg,
                ),
              ),
          ],
        ),
      ),
    );

    return Opacity(
      opacity: disabled ? 0.4 : 1,
      child: GestureDetector(
        onTapDown: disabled ? null : (_) => setState(() => _pressed = true),
        onTapUp: disabled ? null : (_) => setState(() => _pressed = false),
        onTapCancel: disabled ? null : () => setState(() => _pressed = false),
        onTap: disabled ? null : widget.onPressed,
        behavior: HitTestBehavior.opaque,
        child: widget.fullWidth
            ? SizedBox(width: double.infinity, child: child)
            : child,
      ),
    );
  }
}

// IconButton circular pill — variantes ghost / soft / dark.
enum FolhaIconBtnVariant { ghost, soft, dark }

class FolhaIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final FolhaIconBtnVariant variant;
  final double size;
  final String? tooltip;

  const FolhaIconBtn({
    super.key,
    required this.icon,
    this.onPressed,
    this.variant = FolhaIconBtnVariant.ghost,
    this.size = 40,
    this.tooltip,
  });

  ({Color bg, Color fg}) get _v => switch (variant) {
    FolhaIconBtnVariant.ghost => (
      bg: Colors.transparent,
      fg: FolhaColors.ink700,
    ),
    FolhaIconBtnVariant.soft => (bg: FolhaColors.paper200, fg: FolhaColors.ink700),
    FolhaIconBtnVariant.dark => (
      bg: FolhaColors.forest700,
      fg: FolhaColors.paper50,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final v = _v;
    Widget btn = Material(
      color: v.bg,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, size: 20, color: v.fg),
        ),
      ),
    );
    if (tooltip != null) btn = Tooltip(message: tooltip!, child: btn);
    return btn;
  }
}
