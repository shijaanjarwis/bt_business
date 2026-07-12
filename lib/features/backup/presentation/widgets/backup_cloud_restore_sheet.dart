import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/backup/backup_providers.dart';
import '../../../../core/di/core_providers.dart';
import '../../../../core/di/data_revision.dart';
import '../../../../core/theme/app_text_theme.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../shared/widgets/dialogs/app_dialog.dart';
import 'backup_preview_dialogs.dart';

/// Lists cloud backups with setup guide and restore preview.
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
          final statusAsync = ref.watch(backupStatusProvider);
          final metadata = ref.watch(backupMetadataStoreProvider);
          final cloudPort = ref.watch(cloudBackupPortProvider);
          final text = context.appText;

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Cloud Se Wapas Laayein',
                    style: text.primaryBold.copyWith(fontSize: 18),
                  ),
                  const SizedBox(height: 12),
                  statusAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (error, _) => Text('$error', style: text.secondary),
                    data: (status) {
                      if (!status.isConnected) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              '${cloudPort.providerName} abhi set nahi hai.',
                              style: text.primaryBold.copyWith(fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Pehle cloud setup karein. Phir cloud copies dikhengi.',
                              style: text.secondary.copyWith(fontSize: 14),
                            ),
                            const SizedBox(height: 12),
                            FilledButton(
                              onPressed: () async {
                                try {
                                  await cloudPort.ensureConnected();
                                  notifyBackupChanged(ref);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Cloud connected')),
                                    );
                                  }
                                } catch (error) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('$error')),
                                    );
                                  }
                                }
                              },
                              child: const Text('Phir Try Karein'),
                            ),
                          ],
                        );
                      }

                      return cloudAsync.when(
                        loading: () => const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        error: (error, _) => Text('Cloud list fail: $error', style: text.secondary),
                        data: (entries) {
                          if (entries.isEmpty) {
                            return Text(
                              'Cloud par abhi koi copy nahi mili.',
                              style: text.secondary.copyWith(fontSize: 15),
                            );
                          }

                          return Flexible(
                            child: ListView.separated(
                              shrinkWrap: true,
                              itemCount: entries.length,
                              separatorBuilder: (_, _) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final entry = entries[index];
                                final label = metadata.formatDisplayTimestamp(entry.createdAt);
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(label, style: text.primaryBold),
                                  subtitle: Text(entry.fileName, style: text.secondary),
                                  trailing: const Icon(Icons.cloud_download_outlined),
                                  onTap: () async {
                                    final service = ref.read(backupServiceProvider);
                                    try {
                                      final downloaded =
                                          await cloudPort.downloadBackup(entry.remoteId);
                                      final preview =
                                          await service.readFilePreview(downloaded.path);
                                      if (!context.mounted) return;

                                      final confirmed = await showRestorePreviewDialog(
                                        context,
                                        preview: preview,
                                      );
                                      if (!confirmed || !context.mounted) return;

                                      Navigator.of(context).pop();
                                      await service.restoreImportedFile(downloaded.path);
                                      notifyBackupChanged(ref);
                                      notifyDataChanged(ref);
                                      ref.invalidate(appDatabaseProvider);
                                    } catch (error) {
                                      if (context.mounted) {
                                        await AppDialog.show<void>(
                                          context,
                                          child: AppDialog.shell(
                                            context: context,
                                            title: 'Restore fail',
                                            message: '$error',
                                            actions: [
                                              AppDialog.filledAction(
                                                context: context,
                                                label: 'OK',
                                                onPressed: () => Navigator.pop(context),
                                              ),
                                            ],
                                          ),
                                        );
                                      }
                                    }
                                  },
                                );
                              },
                            ),
                          );
                        },
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
