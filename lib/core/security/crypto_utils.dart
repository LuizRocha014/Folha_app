import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

/// Utilitários criptográficos.
///
/// - `newRandomKeyHex` gera uma chave de 256 bits aleatória usando `Random.secure()`,
///   pronta para alimentar o SQLCipher do banco local.
/// - `sha256Hex` hash determinístico (debug / fingerprinting, NUNCA pra senhas).
class CryptoUtils {
  CryptoUtils._();

  static String newRandomKeyHex({int bytes = 32}) {
    final rnd = Random.secure();
    final buffer = List<int>.generate(bytes, (_) => rnd.nextInt(256));
    return buffer.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  static String sha256Hex(String input) {
    final digest = sha256.convert(utf8.encode(input));
    return digest.toString();
  }
}
