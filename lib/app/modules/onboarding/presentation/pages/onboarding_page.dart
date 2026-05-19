import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../../core/routes/app_routes.dart';
import '../../../../../core/theme/folha_colors.dart';
import '../../../../../core/theme/folha_typography.dart';
import '../../../../../core/widgets/folha_widgets.dart';
import '../controllers/onboarding_controller.dart';

class OnboardingPage extends GetView<OnboardingController> {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FolhaColors.paper100,
      body: SafeArea(
        child: Obx(() {
          final step = controller.step.value;
          if (step >= 3) return const _StepDone();
          return Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Visibility(
                      visible: step != 0,
                      maintainState: true,
                      maintainAnimation: true,
                      maintainSize: true,
                      child: FolhaIconBtn(
                        icon: LucideIcons.chevronLeft,
                        variant: FolhaIconBtnVariant.soft,
                        tooltip: 'Voltar',
                        onPressed: controller.prev,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(child: FolhaProgress(step: step, total: 3)),
                    const SizedBox(width: 14),
                    GestureDetector(
                      onTap: () => Get.offAllNamed(AppRoutes.shell),
                      child: Text(
                        'Pular',
                        style: FolhaTypography.body.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: FolhaColors.fgMuted,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Expanded(
                  child: switch (step) {
                    0 => const _StepBank(),
                    1 => const _StepIncome(),
                    _ => const _StepGoal(),
                  },
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

// --- Step 1: Bank ---
class _StepBank extends GetView<OnboardingController> {
  const _StepBank();

  static const _banks = [
    (id: 'nubank', name: 'Nubank', color: Color(0xFF8A05BE)),
    (id: 'itau', name: 'Itaú', color: Color(0xFFFF6B00)),
    (id: 'bb', name: 'Banco do Brasil', color: Color(0xFFFAE128)),
    (id: 'santander', name: 'Santander', color: Color(0xFFEC0000)),
    (id: 'caixa', name: 'Caixa', color: Color(0xFF005CA9)),
    (id: 'inter', name: 'Inter', color: Color(0xFFFF7A00)),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Conecte seu banco.',
          style: FolhaTypography.h2.copyWith(
            fontSize: 30,
            fontStyle: FontStyle.italic,
            color: FolhaColors.forest700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Sincronizamos automaticamente via Pix e Open Finance.\nSem senha. Sem risco.',
          style: FolhaTypography.body.copyWith(
            fontSize: 14,
            color: FolhaColors.ink700,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: Obx(() {
            final selected = controller.bankId.value;
            return ListView.separated(
              itemCount: _banks.length + 1,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                if (i == _banks.length) {
                  return _OtherBankTile();
                }
                final b = _banks[i];
                final active = selected == b.id;
                return Material(
                  color: active
                      ? FolhaColors.forest200
                      : FolhaColors.paper50,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(
                      color: active
                          ? FolhaColors.forest700
                          : FolhaColors.border,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => controller.bankId.value = b.id,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: b.color,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              b.name[0],
                              style: FolhaTypography.titleEditorial(
                                size: 18,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              b.name,
                              style: FolhaTypography.body.copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: FolhaColors.ink900,
                              ),
                            ),
                          ),
                          if (active)
                            const Icon(
                              LucideIcons.check,
                              color: FolhaColors.forest700,
                              size: 20,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          }),
        ),
        const SizedBox(height: 12),
        Obx(
          () => FolhaButton(
            label: controller.bankId.value != null
                ? 'Conectar e continuar'
                : 'Continuar sem conectar',
            size: FolhaButtonSize.lg,
            fullWidth: true,
            onPressed: controller.next,
          ),
        ),
      ],
    );
  }
}

class _OtherBankTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        side: const BorderSide(
          color: FolhaColors.borderStrong,
          style: BorderStyle.solid,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: FolhaColors.paper200,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  LucideIcons.plus,
                  size: 18,
                  color: FolhaColors.ink700,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Outro banco',
                  style: FolhaTypography.body.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: FolhaColors.ink700,
                  ),
                ),
              ),
              const Icon(
                LucideIcons.chevronRight,
                size: 16,
                color: FolhaColors.ink400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Step 2: Income ---
class _StepIncome extends GetView<OnboardingController> {
  const _StepIncome();

  static const _presets = [2500, 3500, 4500, 6000, 8000, 12000];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Quanto entra por mês?',
          style: FolhaTypography.h2.copyWith(
            fontSize: 30,
            fontStyle: FontStyle.italic,
            color: FolhaColors.forest700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Salário, freelas, qualquer renda. Pode ser uma estimativa — você ajusta depois.',
          style: FolhaTypography.body.copyWith(
            fontSize: 14,
            color: FolhaColors.ink700,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 32),
        Expanded(
          child: Column(
            children: [
              Text(
                'RENDA MENSAL APROXIMADA',
                style: FolhaTypography.eyebrow.copyWith(letterSpacing: 0.96),
              ),
              const SizedBox(height: 8),
              Obx(
                () => Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Text(
                        'R\$',
                        style: FolhaTypography.body.copyWith(
                          fontSize: 22,
                          color: FolhaColors.fgMuted,
                        ),
                      ),
                    ),
                    Text(
                      controller.income.value.toInt().toString().replaceAllMapped(
                        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
                        (m) => '${m[1]}.',
                      ),
                      style: FolhaTypography.currencyDisplay(
                        size: 56,
                        color: FolhaColors.forest700,
                        style: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Obx(
                () => Slider(
                  min: 500,
                  max: 20000,
                  divisions: 195,
                  value: controller.income.value.clamp(500, 20000),
                  activeColor: FolhaColors.forest700,
                  inactiveColor: FolhaColors.paper200,
                  onChanged: (v) => controller.income.value = v,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'R\$ 500',
                    style: FolhaTypography.bodySm.copyWith(fontSize: 11),
                  ),
                  Text(
                    'R\$ 20.000',
                    style: FolhaTypography.bodySm.copyWith(fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: _presets.map((p) {
                  return Obx(
                    () => FolhaPill(
                      label:
                          'R\$ ${p.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
                      active: controller.income.value.toInt() == p,
                      onTap: () => controller.income.value = p.toDouble(),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        FolhaButton(
          label: 'Continuar',
          size: FolhaButtonSize.lg,
          fullWidth: true,
          onPressed: controller.next,
        ),
      ],
    );
  }
}

// --- Step 3: Goal ---
class _StepGoal extends GetView<OnboardingController> {
  const _StepGoal();

  static const _labels = [
    'Reserva de emergência',
    'Viagem',
    'Curso ou faculdade',
    'Trocar de carro',
    'Mudar de casa',
    'Outros',
  ];

  String _adjective(int pct) {
    if (pct < 10) return 'pouco';
    if (pct < 20) return 'no caminho';
    if (pct < 35) return 'muito bom';
    return 'ambicioso!';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Sua primeira meta.',
          style: FolhaTypography.h2.copyWith(
            fontSize: 30,
            fontStyle: FontStyle.italic,
            color: FolhaColors.forest700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Quanto você quer guardar por mês? A gente avisa quando você se afasta.',
          style: FolhaTypography.body.copyWith(
            fontSize: 14,
            color: FolhaColors.ink700,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                FolhaField(
                  label: 'Pra quê?',
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _labels.map((l) {
                      return Obx(
                        () => FolhaPill(
                          label: l,
                          active: controller.goalLabel.value == l,
                          onTap: () => controller.goalLabel.value = l,
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'GUARDAR POR MÊS',
                  style: FolhaTypography.eyebrow.copyWith(letterSpacing: 0.96),
                ),
                const SizedBox(height: 8),
                Obx(
                  () => Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Text(
                          'R\$',
                          style: FolhaTypography.body.copyWith(
                            fontSize: 20,
                            color: FolhaColors.fgMuted,
                          ),
                        ),
                      ),
                      Text(
                        controller.goal.value.toInt().toString().replaceAllMapped(
                          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
                          (m) => '${m[1]}.',
                        ),
                        style: FolhaTypography.currencyDisplay(
                          size: 52,
                          color: FolhaColors.forest700,
                          style: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                Obx(
                  () => Text(
                    '${controller.goalPercentage}% da sua renda · ${_adjective(controller.goalPercentage)}',
                    style: FolhaTypography.bodySm.copyWith(
                      color: FolhaColors.ocre700,
                      fontSize: 12,
                    ),
                  ),
                ),
                Obx(
                  () => Slider(
                    min: 50,
                    max: (controller.income.value / 2).clamp(2000, 20000),
                    value: controller.goal.value.clamp(
                      50,
                      (controller.income.value / 2).clamp(2000, 20000),
                    ),
                    divisions: 40,
                    activeColor: FolhaColors.forest700,
                    inactiveColor: FolhaColors.paper200,
                    onChanged: (v) => controller.goal.value = v,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: FolhaColors.forest200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        LucideIcons.trendingUp,
                        size: 22,
                        color: FolhaColors.forest700,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Obx(
                          () => RichText(
                            text: TextSpan(
                              style: FolhaTypography.body.copyWith(
                                fontSize: 13,
                                color: FolhaColors.forest800,
                                height: 1.5,
                              ),
                              children: [
                                const TextSpan(
                                  text: 'Em 12 meses, você junta ',
                                ),
                                TextSpan(
                                  text:
                                      'R\$ ${(controller.goal.value * 12).toInt().toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
                                  style: const TextStyle(
                                    color: FolhaColors.forest900,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const TextSpan(text: '. '),
                                TextSpan(
                                  text: 'Continua assim.',
                                  style: FolhaTypography.titleEditorial(
                                    size: 13,
                                    color: FolhaColors.forest900,
                                  ),
                                ),
                              ],
                            ),
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
        FolhaButton(
          label: 'Definir meta',
          size: FolhaButtonSize.lg,
          fullWidth: true,
          onPressed: controller.next,
        ),
      ],
    );
  }
}

// --- Step 4: Done ---
class _StepDone extends GetView<OnboardingController> {
  const _StepDone();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: FolhaColors.forest900,
      child: Stack(
        children: [
          Positioned(
            left: -160,
            bottom: -120,
            child: Opacity(
              opacity: 0.08,
              child: SvgPicture.asset(
                'assets/svg/leaf-mark.svg',
                width: 500,
                height: 500,
                colorFilter: const ColorFilter.mode(
                  FolhaColors.paper50,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 40, 24, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TUDO PRONTO',
                        style: FolhaTypography.eyebrow.copyWith(
                          color: FolhaColors.forest300,
                        ),
                      ),
                      const SizedBox(height: 8),
                      RichText(
                        text: TextSpan(
                          style: FolhaTypography.h1.copyWith(
                            fontSize: 44,
                            fontStyle: FontStyle.italic,
                            color: FolhaColors.paper50,
                            letterSpacing: -0.88,
                            height: 1.05,
                          ),
                          children: const [
                            TextSpan(text: 'Boas-vindas\nà '),
                            TextSpan(text: 'Folha', style: TextStyle()),
                            TextSpan(text: '.'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: 320,
                        child: Text(
                          'Sua conta está configurada. Daqui pra frente, é só registrar o que entra e o que sai.',
                          style: FolhaTypography.body.copyWith(
                            fontSize: 15,
                            color: FolhaColors.forest300,
                            height: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: FolhaColors.paper50.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color:
                                FolhaColors.paper50.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'SUA META',
                              style: FolhaTypography.eyebrow.copyWith(
                                color: FolhaColors.forest300,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              controller.goalLabel.value,
                              style: FolhaTypography.titleEditorial(
                                size: 22,
                                color: FolhaColors.paper50,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'R\$ ${controller.goal.value.toInt().toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')} por mês · R\$ ${(controller.goal.value * 12).toInt().toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')} no ano',
                              style: FolhaTypography.body.copyWith(
                                fontSize: 13,
                                color: FolhaColors.forest300,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                FolhaButton(
                  label: 'Vamos lá',
                  variant: FolhaButtonVariant.accent,
                  size: FolhaButtonSize.lg,
                  fullWidth: true,
                  onPressed: () => Get.offAllNamed(AppRoutes.shell),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
