import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../../core/routes/app_routes.dart';
import '../../../../../core/theme/folha_colors.dart';
import '../../../../../core/theme/folha_typography.dart';
import '../../../../../core/widgets/folha_widgets.dart';
import '../controllers/auth_controller.dart';

class LoginPage extends GetView<AuthController> {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final emailCtrl = TextEditingController();
    final pwCtrl = TextEditingController();
    final showPw = false.obs;

    return Scaffold(
      backgroundColor: FolhaColors.paper100,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
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
              Expanded(
                child: Column(
                  children: [
                    FolhaField(
                      label: 'Email',
                      child: FolhaInput(
                        controller: emailCtrl,
                        hintText: 'seu@email.com',
                        keyboardType: TextInputType.emailAddress,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Obx(
                      () => FolhaField(
                        label: 'Senha',
                        trailLinkLabel: 'Esqueci',
                        onTrailLinkTap: () {},
                        child: FolhaInput(
                          controller: pwCtrl,
                          hintText: '••••••••',
                          obscureText: !showPw.value,
                          suffix: IconButton(
                            icon: Icon(
                              showPw.value ? LucideIcons.eyeOff : LucideIcons.eye,
                              size: 18,
                              color: FolhaColors.ink400,
                            ),
                            onPressed: () => showPw.value = !showPw.value,
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
                  ],
                ),
              ),
              Obx(
                () => FolhaButton(
                  label: 'Entrar',
                  size: FolhaButtonSize.lg,
                  fullWidth: true,
                  loading: controller.loading.value,
                  onPressed: () async {
                    final ok = await controller.login(
                      email: emailCtrl.text.trim(),
                      password: pwCtrl.text,
                    );
                    if (ok) Get.offAllNamed(AppRoutes.shell);
                  },
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
