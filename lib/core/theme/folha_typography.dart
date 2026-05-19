import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'folha_colors.dart';

/// Folha Typography — Instrument Serif (display) + DM Sans (UI).
/// Todos os styles refletem `.h1 .h2 .body ...` do design system.
class FolhaTypography {
  FolhaTypography._();

  static TextStyle _serif({
    required double size,
    double height = 1.05,
    double letterSpacing = -0.02,
    FontStyle style = FontStyle.normal,
    Color color = FolhaColors.fg,
    FontWeight weight = FontWeight.w400,
  }) {
    return GoogleFonts.instrumentSerif(
      fontSize: size,
      height: height,
      letterSpacing: letterSpacing * size,
      fontStyle: style,
      color: color,
      fontWeight: weight,
    );
  }

  static TextStyle _sans({
    required double size,
    double height = 1.45,
    double letterSpacing = 0,
    Color color = FolhaColors.fg,
    FontWeight weight = FontWeight.w400,
    List<FontFeature>? features,
  }) {
    return GoogleFonts.dmSans(
      fontSize: size,
      height: height,
      letterSpacing: letterSpacing,
      color: color,
      fontWeight: weight,
      fontFeatures: features,
    );
  }

  // Display (serif italic — momentos editoriais)
  static TextStyle displayHero = _serif(size: 84);
  static TextStyle display2 = _serif(size: 60);
  static TextStyle h1 = _serif(size: 44, height: 1.2, letterSpacing: -0.01);
  static TextStyle h2 = _serif(size: 32, height: 1.2, letterSpacing: -0.01);

  // Sans (UI)
  static TextStyle h3 = _sans(
    size: 20,
    height: 1.2,
    letterSpacing: -0.01 * 20,
    weight: FontWeight.w600,
  );
  static TextStyle h4 = _sans(size: 17, height: 1.45, weight: FontWeight.w600);
  static TextStyle bodyLg = _sans(size: 17, height: 1.6);
  static TextStyle body = _sans(size: 15, height: 1.45);
  static TextStyle bodySm = _sans(
    size: 13,
    height: 1.45,
    color: FolhaColors.fgMuted,
  );
  static TextStyle caption = _sans(
    size: 11,
    height: 1.45,
    weight: FontWeight.w500,
    color: FolhaColors.fgMuted,
  );

  // Eyebrow / Overline — UPPERCASE espaçado
  static TextStyle eyebrow = _sans(
    size: 11,
    height: 1.2,
    letterSpacing: 1.32,
    weight: FontWeight.w500,
    color: FolhaColors.fgMuted,
  );

  static TextStyle label = _sans(
    size: 13,
    weight: FontWeight.w500,
    color: FolhaColors.fg,
  );

  // Currency — DM Sans com tabular nums
  static TextStyle currency({
    double size = 15,
    Color color = FolhaColors.fg,
    FontWeight weight = FontWeight.w500,
  }) {
    return _sans(
      size: size,
      color: color,
      weight: weight,
      features: const [FontFeature.tabularFigures(), FontFeature.liningFigures()],
    );
  }

  // Currency big — display serif com tabular nums (hero balance)
  static TextStyle currencyDisplay({
    double size = 54,
    Color color = FolhaColors.fg,
    FontStyle style = FontStyle.normal,
  }) {
    return _serif(
      size: size,
      style: style,
      color: color,
      height: 1,
      letterSpacing: -0.01,
    ).copyWith(
      fontFeatures: const [
        FontFeature.tabularFigures(),
        FontFeature.liningFigures(),
      ],
    );
  }

  // Title editorial italic (Movimentos, Contas, Perfil…)
  static TextStyle titleEditorial({
    double size = 24,
    Color color = FolhaColors.fg,
  }) {
    return _serif(
      size: size,
      style: FontStyle.italic,
      color: color,
      height: 1.1,
      letterSpacing: -0.01,
    );
  }
}
