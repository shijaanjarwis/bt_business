import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_theme.dart';
import '../../../core/theme/color_palette.dart';

/// BT Business dialog — white surface, black text, light scrim overlay.
abstract final class AppDialog {
  static const Color barrier = AppColors.dialogBarrier;
  static const Color surface = AppColors.dialogSurface;

  static Future<T?> show<T>(
    BuildContext context, {
    required Widget child,
    bool barrierDismissible = true,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: barrier,
      builder: (context) => child,
    );
  }

  static AlertDialog shell({
    required BuildContext context,
    Widget? icon,
    required String title,
    String? message,
    List<Widget>? actions,
    Widget? content,
  }) {
    final text = context.appText;
    return AlertDialog(
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      icon: icon,
      title: Text(title, style: text.dialogTitle),
      content: content ??
          (message == null
              ? null
              : Text(message, style: text.dialogBody)),
      actions: actions,
    );
  }

  static TextButton action({
    required BuildContext context,
    required String label,
    required VoidCallback onPressed,
    bool destructive = false,
  }) {
    return TextButton(
      onPressed: onPressed,
      style: destructive
          ? TextButton.styleFrom(foregroundColor: ColorPalette.destructive)
          : TextButton.styleFrom(foregroundColor: AppColors.textPrimary),
      child: Text(
        label,
        style: context.appText.primaryBold.copyWith(fontSize: 15),
      ),
    );
  }

  static FilledButton filledAction({
    required BuildContext context,
    required String label,
    required VoidCallback onPressed,
  }) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: ColorPalette.purple,
        foregroundColor: Colors.white,
      ),
      child: Text(
        label,
        style: context.appText.primaryBold.copyWith(
          fontSize: 15,
          color: Colors.white,
        ),
      ),
    );
  }
}
