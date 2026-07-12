import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/backup/backup_content_stats.dart';
import '../../../../core/theme/app_text_theme.dart';
import '../../../../shared/widgets/dialogs/app_dialog.dart';
import 'backup_preview_panel.dart';

/// Backup preview before create/export.
Future<bool> showBackupPreviewSheet(
  BuildContext context, {
  required BackupPreviewData preview,
  required String confirmLabel,
}) {
  return AppDialog.show<bool>(
    context,
    child: _BackupPreviewDialog(
      preview: preview,
      confirmLabel: confirmLabel,
    ),
  ).then((value) => value ?? false);
}

class _BackupPreviewDialog extends ConsumerWidget {
  const _BackupPreviewDialog({
    required this.preview,
    required this.confirmLabel,
  });

  final BackupPreviewData preview;
  final String confirmLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = context.appText;
    return AppDialog.shell(
      context: context,
      title: 'Copy Preview',
      content: SingleChildScrollView(
        child: BackupPreviewPanel(text: text, preview: preview),
      ),
      actions: [
        AppDialog.action(
          context: context,
          label: 'Cancel',
          onPressed: () => Navigator.pop(context, false),
        ),
        AppDialog.filledAction(
          context: context,
          label: confirmLabel,
          onPressed: () => Navigator.pop(context, true),
        ),
      ],
    );
  }
}

/// Restore preview — confirm before applying backup.
Future<bool> showRestorePreviewDialog(
  BuildContext context, {
  required BackupPreviewData preview,
}) {
  return AppDialog.show<bool>(
    context,
    child: _RestorePreviewDialog(preview: preview),
  ).then((value) => value ?? false);
}

class _RestorePreviewDialog extends StatelessWidget {
  const _RestorePreviewDialog({required this.preview});

  final BackupPreviewData preview;

  @override
  Widget build(BuildContext context) {
    final text = context.appText;
    return AppDialog.shell(
      context: context,
      title: 'Restore this backup?',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Pehle is phone ki copy ban jayegi. Phir chuni hui copy restore hogi.',
            style: text.dialogBody,
          ),
          const SizedBox(height: 12),
          BackupPreviewPanel(
            text: text,
            preview: preview,
            showTransactions: true,
          ),
        ],
      ),
      actions: [
        AppDialog.action(
          context: context,
          label: 'Cancel',
          onPressed: () => Navigator.pop(context, false),
        ),
        AppDialog.filledAction(
          context: context,
          label: 'Restore',
          onPressed: () => Navigator.pop(context, true),
        ),
      ],
    );
  }
}
