import 'package:flutter/material.dart';

import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/color_palette.dart';
import '../labels/bilingual_label.dart';

/// Primary action button — English first line, Hindi second line in parentheses.
class AppPrimaryButton extends StatelessWidget {
  const AppPrimaryButton({
    super.key,
    required this.english,
    required this.hindi,
    required this.onPressed,
    this.isLoading = false,
    this.destructive = false,
    this.compact = false,
  });

  final String english;
  final String hindi;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool destructive;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final backgroundColor =
        destructive ? ColorPalette.destructive : ColorPalette.purple;

    return SizedBox(
      width: double.infinity,
      height: compact ? 48 : AppDimensions.buttonHeight,
      child: FilledButton(
        onPressed: isLoading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: backgroundColor,
          disabledBackgroundColor: backgroundColor.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : BilingualLabel(
                english: english,
                hindi: hindi,
                compact: true,
                crossAxisAlignment: CrossAxisAlignment.center,
                englishStyle: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: compact ? 14 : 16,
                ),
                hindiStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.92),
                  fontWeight: FontWeight.w500,
                  fontSize: compact ? 11 : 12,
                ),
              ),
      ),
    );
  }
}

/// Secondary outlined button — same bilingual label pattern as primary actions.
class AppSecondaryButton extends StatelessWidget {
  const AppSecondaryButton({
    super.key,
    required this.english,
    required this.hindi,
    required this.onPressed,
    this.destructive = false,
  });

  final String english;
  final String hindi;
  final VoidCallback? onPressed;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final foreground =
        destructive ? ColorPalette.destructive : ColorPalette.labelPrimary;

    return SizedBox(
      width: double.infinity,
      height: AppDimensions.buttonHeight,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(AppDimensions.buttonHeight),
          side: BorderSide(
            color: destructive ? ColorPalette.destructive : ColorPalette.border,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
          ),
        ),
        child: BilingualLabel(
          english: english,
          hindi: hindi,
          compact: true,
          crossAxisAlignment: CrossAxisAlignment.center,
          englishStyle: TextStyle(
            color: foreground,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
          hindiStyle: TextStyle(
            color: foreground.withValues(alpha: 0.9),
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
