import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../../../../../core/routes/app_routes.dart';
import '../../../../../core/security/secure_storage_service.dart';
import '../../../../../core/theme/folha_colors.dart';
import '../../../../../core/theme/folha_typography.dart';
import '../../../../../core/widgets/folha_widgets.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  /// Marca a welcome como vista e navega para a rota informada.
  /// A próxima vez que o app abrir sem sessão vai direto pro login.
  Future<void> _goAndMarkSeen(String route) async {
    await Get.find<SecureStorageService>().markWelcomeSeen();
    await Get.toNamed(route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FolhaColors.paper100,
      body: SafeArea(
        child: Stack(
          children: [
            // Folha decorativa
            Positioned(
              right: -160,
              top: -100,
              child: Opacity(
                opacity: 0.06,
                child: SvgPicture.asset(
                  'assets/svg/leaf-mark.svg',
                  width: 500,
                  height: 500,
                  colorFilter: const ColorFilter.mode(
                    FolhaColors.forest700,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SvgPicture.asset('assets/svg/logo.svg', height: 32),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(
                            style: FolhaTypography.h1.copyWith(
                              fontSize: 48,
                              fontStyle: FontStyle.italic,
                              color: FolhaColors.forest700,
                              letterSpacing: -0.96,
                              height: 1.05,
                            ),
                            children: [
                              const TextSpan(
                                text: 'Sua vida\nfinanceira,\nescrita com\n',
                              ),
                              TextSpan(
                                text: 'clareza.',
                                style: TextStyle(color: FolhaColors.ocre500),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: 300,
                          child: Text(
                            'Controle de gastos sem planilha, sem jargão.\n'
                            'Pra quem está aprendendo a cuidar do próprio dinheiro.',
                            style: FolhaTypography.body.copyWith(
                              fontSize: 15,
                              color: FolhaColors.ink700,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  FolhaButton(
                    label: 'Criar conta grátis',
                    size: FolhaButtonSize.lg,
                    fullWidth: true,
                    onPressed: () => _goAndMarkSeen(AppRoutes.signup),
                  ),
                  const SizedBox(height: 10),
                  FolhaButton(
                    label: 'Já tenho conta · Entrar',
                    variant: FolhaButtonVariant.ghost,
                    size: FolhaButtonSize.lg,
                    fullWidth: true,
                    onPressed: () => _goAndMarkSeen(AppRoutes.login),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Ao continuar, você aceita os termos e a política de privacidade.',
                    textAlign: TextAlign.center,
                    style: FolhaTypography.bodySm.copyWith(
                      fontSize: 11,
                      color: FolhaColors.fgSubtle,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
