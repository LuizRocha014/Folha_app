import 'package:flutter/material.dart';

/// Folha Design System — paleta completa
/// Espelha 1:1 os tokens em `colors_and_type.css`.
class FolhaColors {
  FolhaColors._();

  // Paper (backgrounds creme)
  static const paper50 = Color(0xFFFBF8F1);
  static const paper100 = Color(0xFFF4EFE3);
  static const paper200 = Color(0xFFEBE3D0);
  static const paper300 = Color(0xFFDDD2B8);
  static const paper400 = Color(0xFFC7B895);

  // Forest (verde mata — primary)
  static const forest900 = Color(0xFF0B1F18);
  static const forest800 = Color(0xFF112B22);
  static const forest700 = Color(0xFF1A3A2E);
  static const forest600 = Color(0xFF2A5446);
  static const forest500 = Color(0xFF3D8A6A);
  static const forest400 = Color(0xFF6BAE8E);
  static const forest300 = Color(0xFFA4CBB8);
  static const forest200 = Color(0xFFD2E4D8);

  // Ocre (acento raro)
  static const ocre700 = Color(0xFF8C6E2A);
  static const ocre500 = Color(0xFFC8A663);
  static const ocre300 = Color(0xFFE4D2A2);
  static const ocre100 = Color(0xFFF2E8CC);

  // Terra (negativo — mais quente que vermelho)
  static const terra700 = Color(0xFF6F2C1C);
  static const terra500 = Color(0xFFA8442C);
  static const terra300 = Color(0xFFD38670);
  static const terra100 = Color(0xFFF0D9CE);

  // Ink (texto)
  static const ink900 = Color(0xFF1A1612);
  static const ink700 = Color(0xFF3D372E);
  static const ink500 = Color(0xFF6B6354);
  static const ink400 = Color(0xFF8F8775);
  static const ink300 = Color(0xFFB5AC97);
  static const ink200 = Color(0xFFD5CDB8);

  // Semânticos
  static const bg = paper100;
  static const bgElev = paper50;
  static const bgSunken = paper200;
  static const bgInverse = forest900;

  static const fg = ink900;
  static const fgMuted = ink500;
  static const fgSubtle = ink400;
  static const fgOnDark = paper50;
  static const fgOnPrimary = paper50;

  static const border = ink200;
  static const borderStrong = ink300;
  static Color divider = ink200.withValues(alpha: 0.6);

  static const primary = forest700;
  static const primaryHover = forest600;
  static const primaryPress = forest800;
  static const onPrimary = paper50;

  static const accent = ocre500;
  static const positive = forest500;
  static const negative = terra500;
  static const warning = ocre700;
}
