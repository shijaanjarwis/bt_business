import 'package:flutter/material.dart';

import 'color_palette.dart';

/// Typography helpers layered on top of Material 3 [TextTheme].
abstract final class AppTextStyles {
  static TextTheme applyPlatformAdjustments(TextTheme base) {
    return base.copyWith(
      headlineLarge: base.headlineLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.8,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
      ),
      titleSmall: base.titleSmall?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
      ),
      bodySmall: base.bodySmall?.copyWith(
        height: 1.35,
        color: ColorPalette.labelTertiary,
      ),
      bodyMedium: base.bodyMedium?.copyWith(color: ColorPalette.labelSecondary),
      labelMedium: base.labelMedium?.copyWith(color: ColorPalette.labelSecondary),
      labelLarge: base.labelLarge?.copyWith(fontWeight: FontWeight.w600),
    );
  }
}
