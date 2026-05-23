import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../../core/routes/app_routes.dart';
import '../../../../../core/security/biometric_service.dart';
import '../../../../../core/security/secure_storage_service.dart';
import '../../../../../core/theme/folha_colors.dart';
import '../../../../../core/theme/folha_typography.dart';
import '../../../../../core/widgets/folha_widgets.dart';
import '../controllers/auth_controller.dart';
import '../widgets/biometric_enable_dialog.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Controllers vivem no State para sobreviver a rebuilds (ex.: abrir/fechar
  // teclado), do contrário o texto digitado se perde a cada rebuild.
  final _emailCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();

  final _emailFocus = FocusNode();
  final _pwFocus = FocusNode();

  final _showPw = false.obs;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _pwCtrl.dispose();
    _emailFocus.dispose();
    _pwFocus.dispose();
    super.dispose();
  }

  /// Após login OK, oferece habilitar biometria (só se device suporta e não
  /// está habilitada).
  Future<void> _maybeOfferBiometric({
    required AuthController controller,
    required String email,
    required String password,
  }) async {
    final secure = Get.find<SecureStorageService>();
    final biometric = Get.find<BiometricService>();

    if (!await biometric.isAvailable()) return;
    if (await secure.isBiometricEnabled()) return;

    final wants = await Get.dialog<bool>(
      const BiometricEnableDialog(),
      barrierDismissible: false,
    );
    if (wants == true) {
      await controller.enableBiometric(email: email, password: password);
    }
  }

  Future<void> _onSubmit(AuthController controller) async {
    final email = _emailCtrl.text.trim();
    final password = _pwCtrl.text;
    // Fecha o teclado para o usuário ver o loading/dialog.
    FocusScope.of(context).unfocus();

    final ok = await controller.login(email: email, password: password);
    if (!mounted || !ok) return;

    await _maybeOfferBiometric(
      controller: controller,
      email: email,
      password: password,
    );
    if (!mounted) return;
    Get.offAllNamed(AppRoutes.shell);
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AuthController>();
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      backgroundColor: FolhaColors.paper100,
      // Scaffold encurta o body quando o teclado aparece; o SingleChildScrollView
      // abaixo permite que o conteúdo role e o campo focado fique visível.
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          // O padding de baixo cresce com a altura do teclado: o último widget
          // (botão Entrar) fica logo acima do teclado quando o usuário rola.
          padding: EdgeInsets.fromLTRB(24, 12, 24, 28 + bottomInset),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  FolhaIconBtn(
                    icon: LucideIcons.chevronLeft,
                    variant: FolhaIconBtnVariant.soft,
                    tooltip: 'Voltar',
                    onPressed: Get.back,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Bem-vinda de volta.',
                style: FolhaTypography.h2.copyWith(
                  fontSize: 34,
                  fontStyle: FontStyle.italic,
                  color: FolhaColors.forest700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Entra com seu email pra continuar.',
                style: FolhaTypography.body.copyWith(
                  fontSize: 14,
                  color: FolhaColors.ink700,
                ),
              ),
              const SizedBox(height: 28),
              FolhaField(
                label: 'Email',
                child: FolhaInput(
                  controller: _emailCtrl,
                  focusNode: _emailFocus,
                  hintText: 'seu@email.com',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) => _pwFocus.requestFocus(),
                ),
              ),
              const SizedBox(height: 14),
              Obx(
                () => FolhaField(
                  label: 'Senha',
                  trailLinkLabel: 'Esqueci',
                  onTrailLinkTap: () {},
                  child: FolhaInput(
                    controller: _pwCtrl,
                    focusNode: _pwFocus,
                    hintText: '••••••••',
                    obscureText: !_showPw.value,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _onSubmit(controller),
                    suffix: IconButton(
                      icon: Icon(
                        _showPw.value ? LucideIcons.eyeOff : LucideIcons.eye,
                        size: 18,
                        color: FolhaColors.ink400,
                      ),
                      onPressed: () => _showPw.value = !_showPw.value,
                    ),
                  ),
                ),
              ),
              Obx(
                () => controller.error.value != null
                    ? Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            controller.error.value!,
                            style: FolhaTypography.bodySm.copyWith(
                              color: FolhaColors.terra700,
                            ),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              const SizedBox(height: 28),
              Obx(
                () => FolhaButton(
                  label: 'Entrar',
                  size: FolhaButtonSize.lg,
                  fullWidth: true,
                  loading: controller.loading.value,
                  onPressed: () => _onSubmit(controller),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Container(height: 1, color: FolhaColors.divider),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'OU CONTINUE COM',
                      style: FolhaTypography.eyebrow.copyWith(
                        fontSize: 11,
                        color: FolhaColors.fgSubtle,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(height: 1, color: FolhaColors.divider),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: _SocialButton(label: 'Apple', onTap: () {})),
                  const SizedBox(width: 10),
                  Expanded(child: _SocialButton(label: 'Google', onTap: () {})),
                ],
              ),
              const SizedBox(height: 14),
              Center(
                child: RichText(
                  text: TextSpan(
                    style: FolhaTypography.bodySm.copyWith(fontSize: 13),
                    children: [
                      const TextSpan(text: 'Não tem conta? '),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: GestureDetector(
                          onTap: () => Get.offNamed(AppRoutes.signup),
                          child: Text(
                            'Criar uma',
                            style: FolhaTypography.body.copyWith(
                              color: FolhaColors.forest700,
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _SocialButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: FolhaColors.paper50,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: FolhaColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Center(
            child: Text(
              label,
              style: FolhaTypography.body.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: FolhaColors.ink900,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
