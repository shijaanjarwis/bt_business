import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Brand colors — purple primary, Apple-inspired neutrals.
abstract final class ColorPalette {
  static const Color seed = Color(0xFF7B1FA2);
  static const Color purple = Color(0xFF7B1FA2);
  static const Color purpleLight = Color(0xFF9C4DCC);
  static const Color purpleDark = Color(0xFF5E1782);

  static const Color background = Color(0xFFF2F2F7);
  static const Color cardSurface = Color(0xFFFFFFFF);
  static const Color splashBackground = purple;

  /// Primary readable text — party names, titles, amounts.
  static const Color labelPrimary = AppColors.textPrimary;

  /// Secondary readable text — phone, dates, helpers.
  static const Color labelSecondary = AppColors.textSecondary;

  /// Meta / de-emphasized only — never for primary content.
  static const Color labelTertiary = AppColors.textTertiary;

  static const Color hindiText = AppColors.textHindi;
  static const Color hintText = AppColors.textHint;
  static const Color iconPrimary = AppColors.iconPrimary;
  static const Color iconSecondary = AppColors.iconSecondary;
  static const Color border = Color(0xFFD1D1D6);

  static const Color accentBlue = Color(0xFF007AFF);
  static const Color accentGreen = Color(0xFF34C759);
  static const Color accentOrange = Color(0xFFFF9500);
  static const Color destructive = Color(0xFFFF3B30);
  static const Color fieldFill = Color(0xFFF5F5F7);
  static const Color warningSurface = Color(0xFFFFF4E5);
  static const Color warningBorder = Color(0xFFFFD9A0);
  static const Color warningText = Color(0xFFBF5F00);
}
