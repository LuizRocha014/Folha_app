import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../../core/routes/app_routes.dart';
import '../../../../../core/theme/folha_colors.dart';
import '../../../../../core/theme/folha_typography.dart';
import '../../../../../core/widgets/folha_widgets.dart';
import '../controllers/signup_controller.dart';

class SignupPage extends GetView<SignupController> {
  const SignupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FolhaColors.paper100,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
          child: Obx(() {
            final step = controller.step.value;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    FolhaIconBtn(
                      icon: LucideIcons.chevronLeft,
                      variant: FolhaIconBtnVariant.soft,
                      tooltip: 'Voltar',
                      onPressed: () {
                        if (controller.step.value == 0) {
                          Get.back();
                        } else {
                          controller.prev();
                        }
                      },
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: FolhaProgress(step: step, total: 4),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: switch (step) {
                    0 => const _StepAccount(),
                    1 => const _StepIdentity(),
                    2 => const _StepVerify(),
                    _ => const _StepDone(),
                  },
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

// ---------- Step 1 ----------
class _StepAccount extends GetView<SignupController> {
  const _StepAccount();

  @override
  Widget build(BuildContext context) {
    final emailCtrl = TextEditingController(text: controller.email.value);
    final pwCtrl = TextEditingController(text: controller.password.value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Vamos começar pelo básico.',
          style: FolhaTypography.h2.copyWith(
            fontSize: 30,
            fontStyle: FontStyle.italic,
            color: FolhaColors.forest700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Vamos usar seu email pra avisos importantes.',
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
                  onChanged: (v) => controller.email.value = v,
                ),
              ),
              const SizedBox(height: 14),
              FolhaField(
                label: 'Senha',
                hint: 'Mínimo 6 caracteres. Mistura letra, número e símbolo.',
                child: Column(
                  children: [
                    FolhaInput(
                      controller: pwCtrl,
                      hintText: '••••••••',
                      obscureText: true,
                      onChanged: (v) => controller.password.value = v,
                    ),
                    Obx(() {
                      if (controller.password.value.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      final s = controller.passwordStrength();
                      final color = switch (s.severity) {
                        0 || 1 => FolhaColors.terra500,
                        2 => FolhaColors.ocre500,
                        3 => FolhaColors.ocre700,
                        4 => FolhaColors.forest500,
                        _ => FolhaColors.forest700,
                      };
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(999),
                                child: LinearProgressIndicator(
                                  minHeight: 3,
                                  value: s.pct / 100,
                                  backgroundColor: FolhaColors.paper200,
                                  valueColor: AlwaysStoppedAnimation(color),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              s.label.toUpperCase(),
                              style: FolhaTypography.eyebrow.copyWith(
                                color: color,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
        Obx(
          () => FolhaButton(
            label: 'Continuar',
            size: FolhaButtonSize.lg,
            fullWidth: true,
            onPressed:
                controller.account1Valid ? controller.next : null,
          ),
        ),
      ],
    );
  }
}

// ---------- Step 2 ----------
class _StepIdentity extends GetView<SignupController> {
  const _StepIdentity();

  @override
  Widget build(BuildContext context) {
    final nameCtrl = TextEditingController(text: controller.fullName.value);
    final cpfCtrl = TextEditingController(text: controller.cpf.value);
    final birthCtrl = TextEditingController(text: controller.birth.value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Quem é você?',
          style: FolhaTypography.h2.copyWith(
            fontSize: 30,
            fontStyle: FontStyle.italic,
            color: FolhaColors.forest700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Precisamos confirmar sua identidade pra abrir sua conta.',
          style: FolhaTypography.body.copyWith(
            fontSize: 14,
            color: FolhaColors.ink700,
          ),
        ),
        const SizedBox(height: 28),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                FolhaField(
                  label: 'Nome completo',
                  child: FolhaInput(
                    controller: nameCtrl,
                    hintText: 'Como aparece no seu RG',
                    onChanged: (v) => controller.fullName.value = v,
                  ),
                ),
                const SizedBox(height: 14),
                FolhaField(
                  label: 'CPF',
                  child: FolhaInput(
                    controller: cpfCtrl,
                    hintText: '000.000.000-00',
                    keyboardType: TextInputType.number,
                    inputFormatters: [_CpfFormatter()],
                    onChanged: (v) => controller.cpf.value = v,
                  ),
                ),
                const SizedBox(height: 14),
                FolhaField(
                  label: 'Data de nascimento',
                  child: FolhaInput(
                    controller: birthCtrl,
                    hintText: 'DD/MM/AAAA',
                    keyboardType: TextInputType.number,
                    inputFormatters: [_DateFormatter()],
                    onChanged: (v) => controller.birth.value = v,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: FolhaColors.ocre100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        LucideIcons.leaf,
                        size: 16,
                        color: FolhaColors.ocre700,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Seus dados são criptografados e nunca compartilhados.',
                          style: FolhaTypography.body.copyWith(
                            fontSize: 12,
                            color: FolhaColors.ink700,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const _SignupError(),
        const SizedBox(height: 8),
        Obx(
          () => FolhaButton(
            label: 'Continuar',
            size: FolhaButtonSize.lg,
            fullWidth: true,
            loading: controller.loading.value,
            onPressed: controller.identityValid && !controller.loading.value
                ? controller.submitIdentity
                : null,
          ),
        ),
      ],
    );
  }
}

// ---------- Step 3: verificação ----------
class _StepVerify extends GetView<SignupController> {
  const _StepVerify();

  @override
  Widget build(BuildContext context) {
    final codeCtrls = List.generate(6, (_) => TextEditingController());
    final focusNodes = List.generate(6, (_) => FocusNode());

    void onChange(int i, String v) {
      if (v.isNotEmpty && i < 5) focusNodes[i + 1].requestFocus();
      if (v.isEmpty && i > 0) focusNodes[i - 1].requestFocus();
      controller.code.value =
          codeCtrls.map((c) => c.text).join();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Confirme seu email.',
          style: FolhaTypography.h2.copyWith(
            fontSize: 30,
            fontStyle: FontStyle.italic,
            color: FolhaColors.forest700,
          ),
        ),
        const SizedBox(height: 8),
        RichText(
          text: TextSpan(
            style: FolhaTypography.body.copyWith(
              fontSize: 14,
              color: FolhaColors.ink700,
              height: 1.5,
            ),
            children: [
              const TextSpan(text: 'Mandamos um código de 6 dígitos pra '),
              TextSpan(
                text: controller.email.value.isEmpty
                    ? 'seu@email.com'
                    : controller.email.value,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: FolhaColors.ink900,
                ),
              ),
              const TextSpan(text: '.'),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Expanded(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (i) {
                  return SizedBox(
                    width: 48,
                    height: 56,
                    child: TextField(
                      controller: codeCtrls[i],
                      focusNode: focusNodes[i],
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      maxLength: 1,
                      style: FolhaTypography.titleEditorial(size: 24),
                      cursorColor: FolhaColors.forest700,
                      onChanged: (v) => onChange(i, v),
                      decoration: InputDecoration(
                        counterText: '',
                        filled: true,
                        fillColor: FolhaColors.paper50,
                        contentPadding: EdgeInsets.zero,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: FolhaColors.border,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: FolhaColors.forest700,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () async {
                  final ok = await controller.resend();
                  if (ok) {
                    Get.snackbar(
                      'Código reenviado',
                      'Enviamos um novo código para ${controller.email.value}.',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: FolhaColors.forest200,
                      colorText: FolhaColors.forest700,
                      margin: const EdgeInsets.all(16),
                    );
                  }
                },
                child: Text(
                  'Não recebeu? Reenviar código',
                  style: FolhaTypography.body.copyWith(
                    fontSize: 13,
                    color: FolhaColors.forest700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const _SignupError(),
        const SizedBox(height: 8),
        Obx(
          () => FolhaButton(
            label: 'Verificar',
            size: FolhaButtonSize.lg,
            fullWidth: true,
            loading: controller.loading.value,
            onPressed: controller.verifyValid && !controller.loading.value
                ? () async {
                    final ok = await controller.verify();
                    if (ok) controller.next();
                  }
                : null,
          ),
        ),
      ],
    );
  }
}

/// Mensagem de erro do fluxo de cadastro (compartilhada entre as etapas).
class _SignupError extends GetView<SignupController> {
  const _SignupError();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final msg = controller.error.value;
      if (msg == null || msg.isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(LucideIcons.circleAlert, size: 16, color: FolhaColors.terra700),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                msg,
                style: FolhaTypography.bodySm.copyWith(color: FolhaColors.terra700),
              ),
            ),
          ],
        ),
      );
    });
  }
}

// ---------- Step 4 ----------
class _StepDone extends StatelessWidget {
  const _StepDone();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: const BoxDecoration(
              color: FolhaColors.forest200,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.check,
              size: 44,
              color: FolhaColors.forest700,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Conta criada.',
            style: FolhaTypography.h2.copyWith(
              fontSize: 34,
              fontStyle: FontStyle.italic,
              color: FolhaColors.forest700,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: 280,
            child: Text(
              'Agora vamos configurar seu primeiro mês. Leva um minuto.',
              textAlign: TextAlign.center,
              style: FolhaTypography.body.copyWith(
                fontSize: 15,
                color: FolhaColors.ink700,
                height: 1.5,
              ),
            ),
          ),
          const Spacer(),
          FolhaButton(
            label: 'Configurar minha conta',
            size: FolhaButtonSize.lg,
            fullWidth: true,
            onPressed: () => Get.offAllNamed(AppRoutes.onboarding),
          ),
        ],
      ),
    );
  }
}

// ---------- Formatters ----------
class _CpfFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final d = newValue.text.replaceAll(RegExp(r'\D'), '');
    final trimmed = d.length > 11 ? d.substring(0, 11) : d;
    final buf = StringBuffer();
    for (var i = 0; i < trimmed.length; i++) {
      buf.write(trimmed[i]);
      if (i == 2 || i == 5) buf.write('.');
      if (i == 8) buf.write('-');
    }
    return TextEditingValue(
      text: buf.toString(),
      selection: TextSelection.collapsed(offset: buf.length),
    );
  }
}

class _DateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final d = newValue.text.replaceAll(RegExp(r'\D'), '');
    final trimmed = d.length > 8 ? d.substring(0, 8) : d;
    final buf = StringBuffer();
    for (var i = 0; i < trimmed.length; i++) {
      buf.write(trimmed[i]);
      if (i == 1 || i == 3) buf.write('/');
    }
    return TextEditingValue(
      text: buf.toString(),
      selection: TextSelection.collapsed(offset: buf.length),
    );
  }
}
