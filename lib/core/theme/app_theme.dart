import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'color_palette.dart';
import 'text_styles.dart';

/// Material 3 theme definitions — iPhone-first, adaptive on macOS.
abstract final class AppTheme {
  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: ColorPalette.seed,
      brightness: Brightness.light,
      primary: ColorPalette.purple,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: ColorPalette.background,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: ColorPalette.background,
        foregroundColor: ColorPalette.iconPrimary,
        iconTheme: IconThemeData(color: ColorPalette.iconPrimary),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: ColorPalette.cardSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );

    return base.copyWith(
      textTheme: AppTextStyles.applyPlatformAdjustments(base.textTheme),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: TextStyle(color: ColorPalette.hintText),
        labelStyle: const TextStyle(color: ColorPalette.labelTertiary),
        floatingLabelStyle: const TextStyle(color: ColorPalette.labelSecondary),
      ),
    );
  }

  static ThemeData get dark {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: ColorPalette.seed,
      brightness: Brightness.dark,
      primary: ColorPalette.purpleLight,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );

    return base.copyWith(
      textTheme: AppTextStyles.applyPlatformAdjustments(base.textTheme),
    );
  }
}
