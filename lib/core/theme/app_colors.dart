import 'package:flutter/material.dart';

/// Semantic text and surface colors — tuned for outdoor readability (WCAG AA+).
abstract final class AppColors {
  /// Near-black — party names, titles, amounts, important labels.
  static const Color textPrimary = Color(0xFF111111);

  /// Medium-dark grey — phone numbers, dates, Hindi helpers, optional info.
  static const Color textSecondary = Color(0xFF3C3C43);

  /// De-emphasized meta only — developer footer, inactive badges.
  static const Color textTertiary = Color(0xFF636366);

  /// Hindi subtitle lines — slightly darker than generic secondary.
  static const Color textHindi = Color(0xFF2C2C2E);

  /// Placeholders and search hints — still readable in sunlight.
  static const Color textHint = Color(0xFF48484A);

  /// Dialog titles and alert headings.
  static const Color textDialogTitle = textPrimary;

  /// Dialog body — full contrast, not washed-out grey.
  static const Color textDialogBody = textPrimary;

  /// Empty-state messages — secondary but clearly legible.
  static const Color textEmptyState = textSecondary;

  static const Color iconPrimary = textPrimary;
  static const Color iconSecondary = textTertiary;

  /// Modal scrim — ~40% black, dialog stays readable.
  static const Color dialogBarrier = Color(0x66000000);

  /// Dialog surface — always pure white in light theme.
  static const Color dialogSurface = Colors.white;
}
