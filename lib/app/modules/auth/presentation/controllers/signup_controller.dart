import 'dart:developer' as developer;

import 'package:get/get.dart';
import 'auth_controller.dart';

/// Coordena o fluxo multi-step de cadastro (4 etapas):
/// 0 conta → 1 identidade → 2 verificação (código por e-mail) → 3 pronto.
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

  /// E-mail para o qual a conta já foi criada (evita recriar ao voltar/avançar).
  String? _registeredFor;

  // Estados de UI espelhados do AuthController (compartilhado).
  RxBool get loading => auth.loading;
  RxnString get error => auth.error;

  bool get account1Valid =>
      email.value.contains('@') && password.value.length >= 6;

  bool get identityValid =>
      fullName.value.trim().length > 3 &&
      cpf.value.replaceAll(RegExp(r'\D'), '').length == 11 &&
      birth.value.length == 10;

  bool get verifyValid => code.value.length == 6;

  void next() {
    auth.error.value = null;
    step.value = (step.value + 1).clamp(0, 3);
  }

  void prev() {
    auth.error.value = null;
    step.value = (step.value - 1).clamp(0, 3);
  }

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
    } catch (e, st) {
      developer.log('_parseBirth value=${birth.value}', name: 'SignupController', error: e, stackTrace: st);
      return null;
    }
  }

  /// Sai da etapa de identidade: cria a conta e decide o próximo passo.
  /// - Verificação ligada no backend → vai para a tela de código.
  /// - Verificação desligada → loga automático e pula para a conclusão.
  /// Idempotente para o mesmo e-mail (voltar/avançar não recria a conta).
  Future<void> submitIdentity() async {
    final mail = email.value.trim();

    if (_registeredFor != mail) {
      final created = await auth.register(
        email: mail,
        password: password.value,
        fullName: fullName.value.trim(),
        cpf: cpf.value,
        birthDate: _parseBirth(),
      );
      if (created == null) return; // erro já exibido via auth.error
      _registeredFor = mail;

      if (created.emailVerified) {
        // Verificação desligada no backend: já está verificado → loga e conclui.
        final logged = await auth.login(email: mail, password: password.value);
        if (logged) step.value = 3;
        return;
      }
    }

    next(); // precisa confirmar o código → tela de verificação
  }

  /// Confirma o código de 6 dígitos; em caso de sucesso já autentica a sessão.
  Future<bool> verify() => auth.verifyEmail(email: email.value.trim(), code: code.value);

  /// Reenvia o código de verificação para o e-mail do cadastro.
  Future<bool> resend() => auth.resendCode(email: email.value.trim());
}
