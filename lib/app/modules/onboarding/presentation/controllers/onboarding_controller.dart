import 'package:get/get.dart';

/// Estado do fluxo de onboarding (banco, renda, meta).
class OnboardingController extends GetxController {
  final RxInt step = 0.obs;

  // Step 1 — banco
  final RxnString bankId = RxnString();

  // Step 2 — renda
  final RxDouble income = 4200.0.obs;

  // Step 3 — meta
  final RxDouble goal = 800.0.obs;
  final RxString goalLabel = 'Reserva de emergência'.obs;

  void next() => step.value = step.value + 1;
  void prev() => step.value = (step.value - 1).clamp(0, 3);

  int get goalPercentage =>
      income.value == 0 ? 0 : (goal.value / income.value * 100).round();
}
