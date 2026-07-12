import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/backup/backup_format.dart';
import '../../../../core/backup/backup_providers.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/color_palette.dart';

/// Dashboard backup status — 7-day reminder and 30-day critical warning.
class DashboardBackupBanner extends ConsumerWidget {
  const DashboardBackupBanner({super.key});

  Future<void> _backupNow(WidgetRef ref) async {
    await ref.read(backupServiceProvider).createBackup(type: BackupType.manual);
    notifyBackupChanged(ref);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(backupStatusProvider);

    return statusAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (status) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _LastBackupChip(
              label: status.lastBackupLabel,
              onTap: () => context.push(RouteNames.dataSafety),
            ),
            if (status.isCritical) ...[
              const SizedBox(height: AppSpacing.md),
              _WarningBanner(
                color: ColorPalette.destructive.withValues(alpha: 0.12),
                iconColor: ColorPalette.destructive,
                message:
                    'Bahut zaroori — aapka data safe nahi hai. Abhi copy banayein.',
                onOpen: () => context.push(RouteNames.dataSafety),
                onBackupNow: () => _backupNow(ref),
              ),
            ] else if (status.isStale) ...[
              const SizedBox(height: AppSpacing.md),
              _WarningBanner(
                color: ColorPalette.warningSurface,
                iconColor: ColorPalette.warningText,
                message:
                    'Aapka hisaab bahut din se copy nahi hua. Abhi copy banayein.',
                onOpen: () => context.push(RouteNames.dataSafety),
                onBackupNow: () => _backupNow(ref),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _LastBackupChip extends StatelessWidget {
  const _LastBackupChip({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ColorPalette.cardSurface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              const Icon(
                Icons.shield_outlined,
                size: 18,
                color: ColorPalette.purple,
              ),
              const SizedBox(width: 8),
              const Text(
                'Aakhri Copy:',
                style: TextStyle(
                  fontSize: 13,
                  color: ColorPalette.labelSecondary,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.chevron_right_rounded,
                color: ColorPalette.labelSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WarningBanner extends StatelessWidget {
  const _WarningBanner({
    required this.color,
    required this.iconColor,
    required this.message,
    required this.onOpen,
    required this.onBackupNow,
  });

  final Color color;
  final Color iconColor;
  final String message;
  final VoidCallback onOpen;
  final VoidCallback onBackupNow;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: iconColor,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      message,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: iconColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonal(
                  onPressed: onBackupNow,
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                  child: const Text('Abhi Copy Banayein'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
