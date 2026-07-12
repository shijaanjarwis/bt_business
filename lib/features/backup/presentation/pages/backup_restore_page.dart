import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/backup/backup_format.dart';
import '../../../../core/backup/backup_providers.dart';
import '../../presentation/widgets/backup_cloud_restore_sheet.dart';
import '../../../../core/di/core_providers.dart';
import '../../../../core/di/data_revision.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../shared/widgets/branding/developer_footer.dart';
import '../../../../shared/widgets/dialogs/confirmation_dialog.dart';
import '../../../../shared/widgets/feedback/app_error_view.dart';
import '../../../../shared/widgets/feedback/app_loading_view.dart';
import '../../../../shared/widgets/layout/app_form_section.dart';
import '../../../../shared/widgets/scaffold/app_register_app_bar.dart';

/// Hindi-first backup and restore screen — permanent core feature.
class BackupRestorePage extends ConsumerStatefulWidget {
  const BackupRestorePage({super.key});

  @override
  ConsumerState<BackupRestorePage> createState() => _BackupRestorePageState();
}

class _BackupRestorePageState extends ConsumerState<BackupRestorePage> {
  bool _isWorking = false;
  String? _error;

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _isWorking = true;
      _error = null;
    });
    try {
      await action();
      notifyBackupChanged(ref);
      notifyDataChanged(ref);
      ref.invalidate(appDatabaseProvider);
    } catch (error) {
      setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _isWorking = false);
    }
  }

  Future<void> _backupNow() {
    return _run(() async {
      await ref.read(backupServiceProvider).createBackup(type: BackupType.manual);
    });
  }

  Future<void> _importBackup() async {
    final picked = await FilePicker.platform.pickFiles(
      allowedExtensions: ['btbackup'],
      type: FileType.custom,
    );
    if (picked == null || picked.files.isEmpty) return;

    final path = picked.files.single.path;
    if (path == null) return;

    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Backup wapas laayein?',
      message:
          'Pehle is phone ki copy ban jayegi. Phir chuni hui copy restore hogi.',
      confirmLabel: 'Restore',
      cancelLabel: 'Cancel',
      isDestructive: false,
    );
    if (!mounted || confirmed != true) return;

    await _run(() async {
      await ref.read(backupServiceProvider).restoreImportedFile(path);
    });
  }

  Future<void> _restoreEntry(BackupEntry entry) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Backup wapas laayein?',
      message:
          'Pehle is phone ki copy ban jayegi. Phir chuni hui copy restore hogi.',
      confirmLabel: 'Restore',
      cancelLabel: 'Cancel',
      isDestructive: false,
    );
    if (!mounted || confirmed != true) return;

    await _run(() async {
      await ref.read(backupServiceProvider).restoreBackup(entry);
    });
  }

  Future<void> _exportEntry(BackupEntry entry) async {
    await ref.read(backupServiceProvider).exportBackup(entry);
  }

  Future<void> _deleteEntry(BackupEntry entry) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Ye copy delete karein?',
      message: 'Delete ke baad wapas nahi aa sakti.',
      confirmLabel: 'Delete',
    );
    if (confirmed != true) return;

    await _run(() async {
      await ref.read(backupServiceProvider).deleteBackup(entry);
    });
  }

  @override
  Widget build(BuildContext context) {
    final statusAsync = ref.watch(backupStatusProvider);
    final historyAsync = ref.watch(backupHistoryProvider);
    final metadata = ref.watch(backupMetadataStoreProvider);

    return Scaffold(
      backgroundColor: ColorPalette.background,
      appBar: const AppRegisterAppBar(
        english: 'Data Backup',
        hindi: 'Hisaab Ki Copy',
      ),
      body: _isWorking
          ? const AppLoadingView()
          : statusAsync.when(
              loading: () => const AppLoadingView(),
              error: (error, _) => AppErrorView(
                title: 'Backup load nahi ho paya',
                message: '$error',
                actionEnglish: 'Try Again',
                actionHindi: 'Phir Try Karein',
                onAction: () => ref.invalidate(backupStatusProvider),
              ),
              data: (status) {
                if (_error != null) {
                  return AppErrorView(
                    title: 'Backup fail ho gaya',
                    message: _error!,
                    actionEnglish: 'Try Again',
                    actionHindi: 'Phir Try Karein',
                    onAction: () => setState(() => _error = null),
                  );
                }

                return RefreshIndicator(
                  color: ColorPalette.purple,
                  onRefresh: () async {
                    ref.invalidate(backupStatusProvider);
                    ref.invalidate(backupHistoryProvider);
                    await ref.read(backupStatusProvider.future);
                  },
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      AppFormSection(
                        english: 'Backup Status',
                        hindi: 'Copy Ki Haalat',
                        child: Column(
                          children: [
                            _InfoRow(
                              label: 'Aakhri Copy',
                              value: status.lastBackupLabel,
                            ),
                            _InfoRow(
                              label: 'Account',
                              value: status.connectedAccountLabel,
                            ),
                            _InfoRow(
                              label: 'Cloud',
                              value: status.cloudProviderName,
                            ),
                            _InfoRow(
                              label: 'Cloud Copies',
                              value: '${status.cloudBackupCount}',
                            ),
                            _InfoRow(
                              label: 'Jagah Use',
                              value: _formatBytes(status.storageUsedBytes),
                            ),
                            _InfoRow(
                              label: 'Total Copies',
                              value: '${status.backupCount}',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      AppFormSection(
                        english: 'Backup Options',
                        hindi: 'Copy Ke Options',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            FilledButton(
                              onPressed: _backupNow,
                              child: const Text('Abhi Copy Banayein'),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Automatic Copy',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _FrequencyPicker(
                              value: status.autoFrequency,
                              onChanged: (value) async {
                                await metadata.setAutoFrequency(value);
                                notifyBackupChanged(ref);
                              },
                            ),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Sirf WiFi par'),
                              value: status.wifiOnly,
                              onChanged: (value) async {
                                await metadata.setWifiOnly(value);
                                notifyBackupChanged(ref);
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      AppFormSection(
                        english: 'Restore & Export',
                        hindi: 'Wapas Laayein',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            OutlinedButton(
                              onPressed: () => showBackupCloudRestoreSheet(context, ref),
                              child: const Text('Cloud Se Wapas Laayein'),
                            ),
                            const SizedBox(height: 10),
                            OutlinedButton(
                              onPressed: _importBackup,
                              child: const Text('.btbackup File Se Laayein'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      AppFormSection(
                        english: 'Backup History',
                        hindi: 'Purani Copies',
                        child: historyAsync.when(
                          loading: () => const Padding(
                            padding: EdgeInsets.all(12),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                          error: (error, _) => Text('History load fail: $error'),
                          data: (entries) {
                            if (entries.isEmpty) {
                              return const Text('Abhi koi copy nahi bani.');
                            }

                            return Column(
                              children: entries.map((entry) {
                                final label = metadata.formatDisplayTimestamp(
                                  entry.manifest.createdAt,
                                );
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  child: ListTile(
                                    title: Text(label),
                                    subtitle: Text(
                                      '${entry.manifest.businessName} • ${_formatBytes(entry.fileSizeBytes)}',
                                    ),
                                    trailing: PopupMenuButton<String>(
                                      onSelected: (action) {
                                        switch (action) {
                                          case 'restore':
                                            _restoreEntry(entry);
                                          case 'export':
                                            _exportEntry(entry);
                                          case 'delete':
                                            _deleteEntry(entry);
                                        }
                                      },
                                      itemBuilder: (context) => const [
                                        PopupMenuItem(
                                          value: 'restore',
                                          child: Text('Wapas Laayein'),
                                        ),
                                        PopupMenuItem(
                                          value: 'export',
                                          child: Text('Save Karein'),
                                        ),
                                        PopupMenuItem(
                                          value: 'delete',
                                          child: Text('Delete'),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        ),
                      ),
                      const DeveloperFooter(),
                    ],
                  ),
                );
              },
            ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: ColorPalette.labelSecondary),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _FrequencyPicker extends StatelessWidget {
  const _FrequencyPicker({
    required this.value,
    required this.onChanged,
  });

  final AutoBackupFrequency value;
  final ValueChanged<AutoBackupFrequency> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<AutoBackupFrequency>(
      segments: const [
        ButtonSegment(
          value: AutoBackupFrequency.daily,
          label: Text('Roz'),
        ),
        ButtonSegment(
          value: AutoBackupFrequency.weekly,
          label: Text('Hafta'),
        ),
        ButtonSegment(
          value: AutoBackupFrequency.monthly,
          label: Text('Mahina'),
        ),
      ],
      selected: {value},
      onSelectionChanged: (selection) => onChanged(selection.first),
    );
  }
}
