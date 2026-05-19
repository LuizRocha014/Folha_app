import 'package:flutter/material.dart';
import 'folha_colors.dart';
import 'folha_typography.dart';

class FolhaTheme {
  FolhaTheme._();

  static ThemeData light() {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: FolhaColors.bg,
      colorScheme: const ColorScheme.light(
        primary: FolhaColors.primary,
        onPrimary: FolhaColors.onPrimary,
        secondary: FolhaColors.accent,
        onSecondary: FolhaColors.forest900,
        surface: FolhaColors.bgElev,
        onSurface: FolhaColors.fg,
        error: FolhaColors.negative,
        onError: FolhaColors.paper50,
      ),
      textTheme: TextTheme(
        displayLarge: FolhaTypography.displayHero,
        displayMedium: FolhaTypography.display2,
        headlineLarge: FolhaTypography.h1,
        headlineMedium: FolhaTypography.h2,
        headlineSmall: FolhaTypography.h3,
        titleLarge: FolhaTypography.h4,
        bodyLarge: FolhaTypography.bodyLg,
        bodyMedium: FolhaTypography.body,
        bodySmall: FolhaTypography.bodySm,
        labelLarge: FolhaTypography.label,
        labelMedium: FolhaTypography.caption,
        labelSmall: FolhaTypography.eyebrow,
      ),
      splashFactory: InkSparkle.splashFactory,
    );
  }
}
