import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/security/secure_storage_service.dart';
import '../../../core/theme/folha_colors.dart';
import '../../../core/theme/folha_typography.dart';
import '../auth/auth_binding.dart';
import '../auth/presentation/controllers/auth_controller.dart';

/// SplashPage — primeira tela. Decide o destino na ordem:
///
/// 1. **Biometria habilitada** → prompt biométrico imediato. Se OK, vai pro shell.
/// 2. **Sessão restaurável** (tokens válidos no Keychain) → shell.
/// 3. **Já viu welcome** → login.
/// 4. **Primeira vez** → welcome.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    AuthBinding().dependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    final auth = Get.find<AuthController>();
    final secure = Get.find<SecureStorageService>();

    // 1) Biometria habilitada? Dispara o prompt direto. Se passar, joga no shell.
    if (await secure.isBiometricEnabled()) {
      final ok = await auth.loginWithBiometric();
      if (!mounted) return;
      if (ok) {
        Get.offAllNamed(AppRoutes.shell);
        return;
      }
      // Se a biometria falhou ou usuário cancelou, cai pro fluxo normal abaixo.
    }

    // 2) Tem sessão restaurável?
    final user = await auth.tryRestoreSession();
    if (!mounted) return;
    if (user != null) {
      Get.offAllNamed(AppRoutes.shell);
      return;
    }

    // 3/4) Sem sessão — primeira vez vai pra welcome, demais vão direto pro login.
    final seenWelcome = await secure.hasSeenWelcome();
    if (!mounted) return;
    Get.offAllNamed(seenWelcome ? AppRoutes.login : AppRoutes.welcome);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FolhaColors.paper100,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                'assets/svg/leaf-mark.svg',
                width: 56,
                colorFilter: const ColorFilter.mode(
                  FolhaColors.forest700,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Folha',
                style: FolhaTypography.h1.copyWith(
                  fontStyle: FontStyle.italic,
                  fontSize: 36,
                  color: FolhaColors.forest700,
                ),
              ),
              const SizedBox(height: 32),
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  valueColor: AlwaysStoppedAnimation<Color>(FolhaColors.forest700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
