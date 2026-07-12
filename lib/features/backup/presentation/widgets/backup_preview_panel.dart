import 'package:flutter/material.dart';

import '../../../../core/backup/backup_content_stats.dart';
import '../../../../core/theme/app_text_theme.dart';
import '../../../../core/theme/color_palette.dart';

String formatBackupBytes(int bytes) {
  if (bytes <= 0) return '—';
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) {
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

String formatBackupDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/'
      '${date.year}';
}

String formatBackupTime(DateTime date) {
  final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
  final minute = date.minute.toString().padLeft(2, '0');
  final suffix = date.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$minute $suffix';
}

class BackupPreviewPanel extends StatelessWidget {
  const BackupPreviewPanel({
    super.key,
    required this.text,
    required this.preview,
    this.showTransactions = true,
  });

  final AppTextTheme text;
  final BackupPreviewData preview;
  final bool showTransactions;

  @override
  Widget build(BuildContext context) {
    final stats = preview.stats;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorPalette.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ColorPalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Copy Preview', style: text.primaryBold.copyWith(fontSize: 17)),
          const SizedBox(height: 12),
          _PreviewRow(text: text, label: 'Backup Date', value: formatBackupDate(preview.backupDate)),
          _PreviewRow(text: text, label: 'Backup Time', value: formatBackupTime(preview.backupDate)),
          _PreviewRow(text: text, label: 'App Version', value: preview.appVersion),
          _PreviewRow(
            text: text,
            label: 'Database Size',
            value: formatBackupBytes(
              stats.databaseSizeBytes > 0
                  ? stats.databaseSizeBytes
                  : preview.fileSizeBytes,
            ),
          ),
          if (preview.fileSizeBytes > 0)
            _PreviewRow(
              text: text,
              label: 'File Size',
              value: formatBackupBytes(preview.fileSizeBytes),
            ),
          const Divider(height: 20),
          _PreviewRow(text: text, label: 'Parties', value: '${stats.partyCount}'),
          _PreviewRow(text: text, label: 'Items', value: '${stats.itemCount}'),
          _PreviewRow(text: text, label: 'Sale Entries', value: '${stats.saleCount}'),
          _PreviewRow(text: text, label: 'Purchase Entries', value: '${stats.purchaseCount}'),
          _PreviewRow(text: text, label: 'Expense Entries', value: '${stats.expenseCount}'),
          _PreviewRow(text: text, label: 'Ledger Entries', value: '${stats.ledgerEntryCount}'),
          if (showTransactions)
            _PreviewRow(
              text: text,
              label: 'Transactions',
              value: '${stats.transactionCount}',
            ),
          if (preview.storageLocation != null) ...[
            const SizedBox(height: 4),
            _PreviewRow(
              text: text,
              label: 'Storage',
              value: preview.storageLocation!,
            ),
          ],
        ],
      ),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  const _PreviewRow({
    required this.text,
    required this.label,
    required this.value,
  });

  final AppTextTheme text;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: text.secondary.copyWith(fontSize: 14)),
          ),
          Text(value, style: text.primaryBold.copyWith(fontSize: 14)),
        ],
      ),
    );
  }
}
