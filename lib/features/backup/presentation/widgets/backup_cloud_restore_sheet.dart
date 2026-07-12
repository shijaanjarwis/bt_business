import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/backup/backup_providers.dart';
import '../../../../core/di/core_providers.dart';
import '../../../../core/di/data_revision.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../shared/widgets/dialogs/confirmation_dialog.dart';

/// Lists cloud backups and restores the selected encrypted copy.
Future<void> showBackupCloudRestoreSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: ColorPalette.cardSurface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) {
      return Consumer(
        builder: (context, ref, _) {
          final cloudAsync = ref.watch(cloudBackupHistoryProvider);
          final metadata = ref.watch(backupMetadataStoreProvider);

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Cloud Se Wapas Laayein',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  cloudAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (error, _) => Text('Cloud list fail: $error'),
                    data: (entries) {
                      if (entries.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Text('Cloud par abhi koi copy nahi mili.'),
                        );
                      }

                      return Flexible(
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: entries.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final entry = entries[index];
                            final label = metadata.formatDisplayTimestamp(
                              entry.createdAt,
                            );
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(label),
                              subtitle: Text(entry.fileName),
                              trailing: const Icon(Icons.cloud_download_outlined),
                              onTap: () async {
                                final confirmed = await ConfirmationDialog.show(
                                  context,
                                  title: 'Cloud copy restore karein?',
                                  message:
                                      'Pehle is phone ki copy ban jayegi. Phir cloud copy restore hogi.',
                                  confirmLabel: 'Restore',
                                  cancelLabel: 'Cancel',
                                  isDestructive: false,
                                );
                                if (confirmed != true || !context.mounted) return;

                                Navigator.of(context).pop();
                                try {
                                  await ref
                                      .read(backupServiceProvider)
                                      .restoreFromCloud(entry);
                                  notifyBackupChanged(ref);
                                  notifyDataChanged(ref);
                                  ref.invalidate(appDatabaseProvider);
                                } catch (error) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('$error')),
                                    );
                                  }
                                }
                              },
                            );
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
