import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Named text styles for BT Business — use via [Theme.of(context).extension].
class AppTextTheme extends ThemeExtension<AppTextTheme> {
  const AppTextTheme({
    required this.partyName,
    required this.partyPhone,
    required this.listTitle,
    required this.listSubtitle,
    required this.primary,
    required this.primaryBold,
    required this.secondary,
    required this.caption,
    required this.hindi,
    required this.helper,
    required this.emptyState,
    required this.dialogTitle,
    required this.dialogBody,
    required this.amount,
    required this.meta,
  });

  final TextStyle partyName;
  final TextStyle partyPhone;
  final TextStyle listTitle;
  final TextStyle listSubtitle;
  final TextStyle primary;
  final TextStyle primaryBold;
  final TextStyle secondary;
  final TextStyle caption;
  final TextStyle hindi;
  final TextStyle helper;
  final TextStyle emptyState;
  final TextStyle dialogTitle;
  final TextStyle dialogBody;
  final TextStyle amount;
  final TextStyle meta;

  static const AppTextTheme standard = AppTextTheme(
    partyName: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
      height: 1.25,
      letterSpacing: -0.2,
    ),
    partyPhone: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: AppColors.textSecondary,
      height: 1.3,
    ),
    listTitle: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
      height: 1.25,
      letterSpacing: -0.2,
    ),
    listSubtitle: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: AppColors.textSecondary,
      height: 1.3,
    ),
    primary: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      color: AppColors.textPrimary,
      height: 1.35,
    ),
    primaryBold: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
      height: 1.25,
      letterSpacing: -0.2,
    ),
    secondary: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: AppColors.textSecondary,
      height: 1.35,
    ),
    caption: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: AppColors.textSecondary,
      height: 1.35,
    ),
    hindi: TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: AppColors.textHindi,
      height: 1.35,
    ),
    helper: TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: AppColors.textSecondary,
      height: 1.35,
    ),
    emptyState: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      color: AppColors.textEmptyState,
      height: 1.4,
    ),
    dialogTitle: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w700,
      color: AppColors.textDialogTitle,
      height: 1.25,
      letterSpacing: -0.3,
    ),
    dialogBody: TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w500,
      color: AppColors.textDialogBody,
      height: 1.45,
    ),
    amount: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
      height: 1.1,
      letterSpacing: -0.3,
    ),
    meta: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: AppColors.textTertiary,
      height: 1.35,
    ),
  );

  @override
  AppTextTheme copyWith({
    TextStyle? partyName,
    TextStyle? partyPhone,
    TextStyle? listTitle,
    TextStyle? listSubtitle,
    TextStyle? primary,
    TextStyle? primaryBold,
    TextStyle? secondary,
    TextStyle? caption,
    TextStyle? hindi,
    TextStyle? helper,
    TextStyle? emptyState,
    TextStyle? dialogTitle,
    TextStyle? dialogBody,
    TextStyle? amount,
    TextStyle? meta,
  }) {
    return AppTextTheme(
      partyName: partyName ?? this.partyName,
      partyPhone: partyPhone ?? this.partyPhone,
      listTitle: listTitle ?? this.listTitle,
      listSubtitle: listSubtitle ?? this.listSubtitle,
      primary: primary ?? this.primary,
      primaryBold: primaryBold ?? this.primaryBold,
      secondary: secondary ?? this.secondary,
      caption: caption ?? this.caption,
      hindi: hindi ?? this.hindi,
      helper: helper ?? this.helper,
      emptyState: emptyState ?? this.emptyState,
      dialogTitle: dialogTitle ?? this.dialogTitle,
      dialogBody: dialogBody ?? this.dialogBody,
      amount: amount ?? this.amount,
      meta: meta ?? this.meta,
    );
  }

  @override
  AppTextTheme lerp(ThemeExtension<AppTextTheme>? other, double t) {
    if (other is! AppTextTheme) return this;
    return this;
  }
}

/// Convenient access: `context.appText.partyName`
extension AppTextThemeContext on BuildContext {
  AppTextTheme get appText =>
      Theme.of(this).extension<AppTextTheme>() ?? AppTextTheme.standard;
}
