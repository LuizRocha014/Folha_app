import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

/// Wrapper sobre `local_auth` para reconhecimento biométrico (digital, Face ID).
///
/// Uso típico:
/// ```dart
/// if (await biometric.isAvailable()) {
///   final ok = await biometric.authenticate(reason: 'Use sua digital pra entrar');
///   if (ok) { ... }
/// }
/// ```
class BiometricService {
  BiometricService({LocalAuthentication? auth}) : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  /// O device tem biometria configurada e disponível?
  Future<bool> isAvailable() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final supported = await _auth.isDeviceSupported();
      if (!canCheck || !supported) return false;
      final enrolled = await _auth.getAvailableBiometrics();
      return enrolled.isNotEmpty;
    } on PlatformException {
      return false;
    }
  }

  /// Lista tipos de biometria disponíveis (fingerprint, face, etc.).
  Future<List<BiometricType>> enrolled() async {
    try {
      return await _auth.getAvailableBiometrics();
    } on PlatformException {
      return const [];
    }
  }

  /// Dispara o prompt biométrico. Retorna true se o usuário autenticou.
  Future<bool> authenticate({
    required String reason,
    bool stickyAuth = true,
  }) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          stickyAuth: stickyAuth,
          biometricOnly: true,
          useErrorDialogs: true,
        ),
      );
    } on PlatformException {
      return false;
    }
  }

  /// Cancela uma autenticação em andamento (útil em logout forçado).
  Future<void> cancel() async {
    try {
      await _auth.stopAuthentication();
    } on PlatformException {
      // ignore
    }
  }
}
