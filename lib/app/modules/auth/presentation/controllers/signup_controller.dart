import 'package:get/get.dart';
import 'auth_controller.dart';

/// Coordena o fluxo multi-step de cadastro (4 etapas).
/// Mantém o estado do formulário independente do AuthController (que só sabe da sessão final).
class SignupController extends GetxController {
  final AuthController auth;
  SignupController({required this.auth});

  final RxInt step = 0.obs;

  // Step 1 — conta
  final RxString email = ''.obs;
  final RxString password = ''.obs;

  // Step 2 — identidade
  final RxString fullName = ''.obs;
  final RxString cpf = ''.obs;
  final RxString birth = ''.obs; // DD/MM/AAAA

  // Step 3 — verificação
  final RxString code = ''.obs;

  bool get account1Valid =>
      email.value.contains('@') && password.value.length >= 6;

  bool get identityValid =>
      fullName.value.trim().length > 3 &&
      cpf.value.replaceAll(RegExp(r'\D'), '').length == 11 &&
      birth.value.length == 10;

  bool get verifyValid => code.value.length == 6;

  void next() => step.value = (step.value + 1).clamp(0, 3);
  void prev() => step.value = (step.value - 1).clamp(0, 3);

  /// Strength da senha — retorna (pct 0..100, label, severity 0..5).
  ({int pct, String label, int severity}) passwordStrength() {
    var s = 0;
    final p = password.value;
    if (p.length >= 6) s++;
    if (p.length >= 10) s++;
    if (RegExp(r'[A-Z]').hasMatch(p) && RegExp(r'[a-z]').hasMatch(p)) s++;
    if (RegExp(r'[0-9]').hasMatch(p)) s++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(p)) s++;
    const labels = ['Fraca', 'Fraca', 'Média', 'Boa', 'Forte', 'Ótima'];
    const pcts = [10, 25, 50, 75, 90, 100];
    return (pct: pcts[s], label: labels[s], severity: s);
  }

  DateTime? _parseBirth() {
    try {
      final parts = birth.value.split('/');
      if (parts.length != 3) return null;
      return DateTime(
        int.parse(parts[2]),
        int.parse(parts[1]),
        int.parse(parts[0]),
      );
    } catch (_) {
      return null;
    }
  }

  Future<bool> finalize() async {
    final b = _parseBirth();
    if (b == null) return false;
    return auth.signup(
      email: email.value,
      password: password.value,
      fullName: fullName.value,
      cpf: cpf.value,
      birthDate: b,
    );
  }
}
