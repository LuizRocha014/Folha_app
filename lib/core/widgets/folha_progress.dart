import 'package:flutter/material.dart';
import '../theme/folha_colors.dart';
import '../theme/folha_tokens.dart';

/// Progress bar segmentado para fluxos multi-step (signup, onboarding).
class FolhaProgress extends StatelessWidget {
  final int step;
  final int total;

  const FolhaProgress({super.key, required this.step, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total, (i) {
        return Expanded(
          child: AnimatedContainer(
            duration: FolhaDuration.med,
            height: 3,
            margin: EdgeInsets.only(right: i < total - 1 ? 4 : 0),
            decoration: BoxDecoration(
              color: i <= step ? FolhaColors.forest700 : FolhaColors.paper300,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        );
      }),
    );
  }
}
