import 'package:flutter/material.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_text_theme.dart';
import '../../../core/theme/color_palette.dart';
import '../buttons/app_primary_button.dart';

/// Reusable full-screen error state with optional retry or navigation action.
class AppErrorView extends StatelessWidget {
  const AppErrorView({
    super.key,
    required this.title,
    required this.message,
    this.actionEnglish,
    this.actionHindi,
    this.onAction,
    this.icon = Icons.error_outline_rounded,
  });

  final String title;
  final String message;
  final String? actionEnglish;
  final String? actionHindi;
  final VoidCallback? onAction;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: ColorPalette.iconPrimary),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              textAlign: TextAlign.center,
              style: context.appText.primaryBold.copyWith(fontSize: 17),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: context.appText.secondary,
            ),
            if (actionEnglish != null &&
                actionHindi != null &&
                onAction != null) ...[
              const SizedBox(height: AppSpacing.xl),
              AppPrimaryButton(
                english: actionEnglish!,
                hindi: actionHindi!,
                onPressed: onAction,
                compact: true,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
