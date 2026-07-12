import 'package:flutter/material.dart';

import '../../../../core/backup/backup_format.dart';
import '../../../../core/theme/app_text_theme.dart';
import '../../../../core/theme/color_palette.dart';
import 'backup_preview_panel.dart';

class BackupHistoryCard extends StatelessWidget {
  const BackupHistoryCard({
    super.key,
    required this.text,
    required this.item,
    required this.dateLabel,
    required this.onRestore,
    required this.onShare,
    required this.onDelete,
  });

  final AppTextTheme text;
  final BackupHistoryItem item;
  final String dateLabel;
  final VoidCallback? onRestore;
  final VoidCallback? onShare;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final isSuccess = item.isSuccess;
    final entry = item.entry;
    final createdAt = isSuccess
        ? entry!.manifest.createdAt
        : item.failedAt ?? DateTime.now();
    final size = isSuccess ? entry!.fileSizeBytes : 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ColorPalette.cardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSuccess ? ColorPalette.border : ColorPalette.destructive.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  dateLabel,
                  style: text.primaryBold.copyWith(fontSize: 15),
                ),
              ),
              _StatusChip(
                text: text,
                label: isSuccess ? 'Success' : 'Failed',
                color: isSuccess ? ColorPalette.accentGreen : ColorPalette.destructive,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${formatBackupDate(createdAt)} • ${formatBackupTime(createdAt)}',
            style: text.secondary.copyWith(fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            isSuccess
                ? '${formatBackupBytes(size)} • ${item.storageLocation}'
                : item.errorMessage ?? 'Copy fail ho gayi',
            style: text.primary.copyWith(
              fontSize: 14,
              color: isSuccess ? ColorPalette.labelPrimary : ColorPalette.destructive,
            ),
          ),
          if (isSuccess) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: PopupMenuButton<String>(
                onSelected: (action) {
                  switch (action) {
                    case 'restore':
                      onRestore?.call();
                    case 'share':
                      onShare?.call();
                    case 'delete':
                      onDelete?.call();
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'restore', child: Text('Restore')),
                  PopupMenuItem(value: 'share', child: Text('Share')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.text,
    required this.label,
    required this.color,
  });

  final AppTextTheme text;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: text.caption.copyWith(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
