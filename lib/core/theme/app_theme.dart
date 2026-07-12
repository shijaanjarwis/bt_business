import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_text_theme.dart';
import 'color_palette.dart';
import 'text_styles.dart';

/// Material 3 theme definitions — iPhone-first, adaptive on macOS.
abstract final class AppTheme {
  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: ColorPalette.seed,
      brightness: Brightness.light,
      primary: ColorPalette.purple,
      onSurface: AppColors.textPrimary,
      onSurfaceVariant: AppColors.textSecondary,
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
      iconTheme: const IconThemeData(
        color: AppColors.iconPrimary,
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.iconPrimary,
        titleTextStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          height: 1.25,
          letterSpacing: -0.2,
        ),
        subtitleTextStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
          height: 1.3,
        ),
      ),
      dialogTheme: const DialogThemeData(
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.textDialogTitle,
          height: 1.25,
          letterSpacing: -0.3,
        ),
        contentTextStyle: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: AppColors.textDialogBody,
          height: 1.45,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: ColorPalette.cardSurface,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: ColorPalette.cardSurface,
        selectedColor: ColorPalette.purple,
        disabledColor: ColorPalette.cardSurface,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
        secondaryLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        checkmarkColor: ColorPalette.purpleLight,
        brightness: Brightness.light,
        elevation: 0,
        pressElevation: 0,
        side: const BorderSide(color: Color(0xFFD1D5DB)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        surfaceTintColor: Colors.transparent,
      ),
    );

    return base.copyWith(
      textTheme: AppTextStyles.buildTextTheme(base.textTheme),
      primaryTextTheme: AppTextStyles.buildTextTheme(base.primaryTextTheme),
      extensions: const [AppTextTheme.standard],
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: const TextStyle(
          color: AppColors.textHint,
          fontWeight: FontWeight.w400,
          fontSize: 16,
        ),
        labelStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        floatingLabelStyle: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        helperStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
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
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainerHighest,
        selectedColor: colorScheme.primary,
        disabledColor: colorScheme.surfaceContainerHighest,
        checkmarkColor: colorScheme.onPrimary,
        brightness: Brightness.dark,
        elevation: 0,
        pressElevation: 0,
        side: BorderSide(color: colorScheme.outlineVariant),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        surfaceTintColor: Colors.transparent,
      ),
    );

    return base.copyWith(
      textTheme: AppTextStyles.buildTextTheme(base.textTheme),
      extensions: const [AppTextTheme.standard],
    );
  }
}
