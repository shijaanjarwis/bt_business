import 'package:flutter/material.dart';

import 'app_dialog.dart';

/// Global confirmation dialog — English-only action buttons.
class ConfirmationDialog extends StatelessWidget {
  const ConfirmationDialog({
    super.key,
    required this.title,
    this.message,
    this.confirmLabel = 'Delete',
    this.cancelLabel = 'Cancel',
    this.isDestructive = true,
  });

  final String title;
  final String? message;
  final String confirmLabel;
  final String cancelLabel;
  final bool isDestructive;

  static Future<bool?> show(
    BuildContext context, {
    required String title,
    String? message,
    String confirmLabel = 'Delete',
    String cancelLabel = 'Cancel',
    bool isDestructive = true,
  }) {
    return AppDialog.show<bool>(
      context,
      child: ConfirmationDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        isDestructive: isDestructive,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppDialog.shell(
      context: context,
      title: title,
      message: message,
      actions: [
        AppDialog.action(
          context: context,
          label: cancelLabel,
          onPressed: () => Navigator.of(context).pop(false),
        ),
        AppDialog.action(
          context: context,
          label: confirmLabel,
          onPressed: () => Navigator.of(context).pop(true),
          destructive: isDestructive,
        ),
      ],
    );
  }
}
