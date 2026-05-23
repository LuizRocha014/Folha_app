import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../../core/theme/folha_colors.dart';

/// Tab bar flutuante com FAB central — espelha o protótipo Folha.
/// 5 itens visuais: Início, Movimentos, [+], Contas, Perfil.
/// Logicamente são 4 tabs (índices 0..3) — o `+` chama `onAddPressed`.
class FolhaTabBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onAddPressed;

  const FolhaTabBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.onAddPressed,
  });

  static const _items = [
    (icon: LucideIcons.home, label: 'Início'),
    (icon: LucideIcons.arrowLeftRight, label: 'Movimentos'),
    null, // FAB slot
    (icon: LucideIcons.wallet, label: 'Contas'),
    (icon: LucideIcons.user, label: 'Perfil'),
  ];

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      // Stack para o FAB poder ultrapassar o topo da barra sem ser clipado.
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Pílula com blur
          ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: FolhaColors.paper50.withValues(alpha: 0.86),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: FolhaColors.divider),
                  boxShadow: [
                    BoxShadow(
                      color: FolhaColors.forest900.withValues(alpha: 0.18),
                      offset: const Offset(0, 10),
                      blurRadius: 32,
                      spreadRadius: -8,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(_items.length, (i) {
                    if (_items[i] == null) {
                      // Slot vazio reservado para o FAB (que vive fora do ClipRRect).
                      return const SizedBox(width: 50, height: 50);
                    }
                    final item = _items[i]!;
                    final logicalIndex = i < 2 ? i : i - 1;
                    final active = currentIndex == logicalIndex;
                    return _TabItem(
                      icon: item.icon,
                      label: item.label,
                      active: active,
                      onTap: () => onTap(logicalIndex),
                    );
                  }),
                ),
              ),
            ),
          ),
          // FAB sobreposto, levantando 22dp acima da barra.
          Positioned(
            top: -22,
            left: 0,
            right: 0,
            child: Center(child: _Fab(onTap: onAddPressed)),
          ),
        ],
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _TabItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? FolhaColors.forest700 : FolhaColors.ink400;
    return InkResponse(
      onTap: onTap,
      radius: 28,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                color: color,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Fab extends StatefulWidget {
  final VoidCallback onTap;
  const _Fab({required this.onTap});

  @override
  State<_Fab> createState() => _FabState();
}

class _FabState extends State<_Fab> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.92 : 1,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: FolhaColors.forest700,
            shape: BoxShape.circle,
            border: Border.all(color: FolhaColors.paper50, width: 4),
            boxShadow: [
              BoxShadow(
                color: FolhaColors.forest900.withValues(alpha: 0.35),
                offset: const Offset(0, 6),
                blurRadius: 16,
                spreadRadius: -2,
              ),
            ],
          ),
          child: const Icon(
            LucideIcons.plus,
            color: FolhaColors.paper50,
            size: 26,
          ),
        ),
      ),
    );
  }
}
