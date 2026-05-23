import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../../core/theme/folha_colors.dart';
import '../../../../../core/theme/folha_typography.dart';
import '../../../../../core/widgets/folha_widgets.dart';

/// Pergunta ao usuário se ele quer ativar login com digital nas próximas vezes.
///
/// Retorna `true` se aceitar, `false` se recusar, `null` se fechar.
class BiometricEnableDialog extends StatelessWidget {
  const BiometricEnableDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: FolhaColors.paper100,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: FolhaColors.forest200,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.fingerprint,
                size: 36,
                color: FolhaColors.forest700,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Entrar com a digital?',
              style: FolhaTypography.titleEditorial(size: 22),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Da próxima vez que abrir a Folha, você entra rapidinho '
              'tocando o sensor — sem digitar email e senha.',
              textAlign: TextAlign.center,
              style: FolhaTypography.body.copyWith(
                fontSize: 13,
                color: FolhaColors.ink700,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 20),
            FolhaButton(
              label: 'Sim, habilitar',
              size: FolhaButtonSize.lg,
              fullWidth: true,
              onPressed: () => Get.back(result: true),
            ),
            const SizedBox(height: 6),
            TextButton(
              onPressed: () => Get.back(result: false),
              child: Text(
                'Agora não',
                style: FolhaTypography.body.copyWith(
                  fontSize: 13,
                  color: FolhaColors.fgMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
