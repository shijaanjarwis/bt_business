import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';

import '../../../../core/backup/backup_format.dart';
import '../../../../core/backup/backup_providers.dart';
import '../../../../core/di/core_providers.dart';
import '../../../../core/di/data_revision.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_text_theme.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../shared/widgets/branding/developer_footer.dart';
import '../../../../shared/widgets/dialogs/confirmation_dialog.dart';
import '../../../../shared/widgets/feedback/app_error_view.dart';
import '../../../../shared/widgets/feedback/app_loading_view.dart';
import '../../../../shared/widgets/layout/app_form_section.dart';
import '../../../../shared/widgets/scaffold/app_register_app_bar.dart';
import '../widgets/backup_cloud_restore_sheet.dart';

/// Data Safety Center — backup, restore, export, import, and status.
class DataSafetyPage extends ConsumerStatefulWidget {
  const DataSafetyPage({super.key});

  @override
  ConsumerState<DataSafetyPage> createState() => _DataSafetyPageState();
}

class _DataSafetyPageState extends ConsumerState<DataSafetyPage> {
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

  Future<void> _exportLatest() {
    return _run(() async {
      await ref.read(backupServiceProvider).exportLatestBackup();
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
    if (!mounted) return;

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
        english: 'Data Safety',
        hindi: 'Data Suraksha',
      ),
      body: _isWorking
          ? const AppLoadingView()
          : statusAsync.when(
              loading: () => const AppLoadingView(),
              error: (error, _) => AppErrorView(
                title: 'Data Safety load nahi ho paya',
                message: '$error',
                actionEnglish: 'Try Again',
                actionHindi: 'Phir Try Karein',
                onAction: () => ref.invalidate(backupStatusProvider),
              ),
              data: (status) {
                if (_error != null) {
                  return AppErrorView(
                    title: 'Kaam fail ho gaya',
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
                      _SetupEntryCard(
                        onTap: () => context.push(RouteNames.backup),
                      ),
                      const SizedBox(height: 16),
                      _SectionHeader(
                        icon: Icons.shield_outlined,
                        title: 'Data Suraksha',
                        subtitle: 'Aapka poora hisaab safe rakhein',
                      ),
                      const SizedBox(height: 16),
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
                              label: 'Agli Automatic Copy',
                              value: status.nextAutomaticBackupLabel,
                            ),
                            _InfoRow(
                              label: 'Automatic Copy',
                              value: status.autoBackupEnabled ? 'Chalu' : 'Band',
                            ),
                            _InfoRow(
                              label: 'Copy Ka Size',
                              value: status.latestBackupSizeBytes > 0
                                  ? _formatBytes(status.latestBackupSizeBytes)
                                  : '—',
                            ),
                            _InfoRow(
                              label: 'Jagah Use',
                              value: _formatBytes(status.storageUsedBytes),
                            ),
                            _InfoRow(
                              label: 'Cloud',
                              value: status.cloudProviderName,
                            ),
                            _InfoRow(
                              label: 'Account',
                              value: status.connectedAccountLabel,
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
                        english: 'Backup & Restore',
                        hindi: 'Copy Banayein / Wapas Laayein',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            FilledButton.icon(
                              onPressed: _backupNow,
                              icon: const Icon(Icons.backup_outlined),
                              label: const Text('Abhi Copy Banayein'),
                            ),
                            const SizedBox(height: 10),
                            OutlinedButton(
                              onPressed: () =>
                                  showBackupCloudRestoreSheet(context, ref),
                              child: const Text('Cloud Se Wapas Laayein'),
                            ),
                            const SizedBox(height: 10),
                            OutlinedButton(
                              onPressed: _importBackup,
                              child: const Text('.btbackup Se Wapas Laayein'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      AppFormSection(
                        english: 'Export & Import',
                        hindi: 'Save / Laayein',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            OutlinedButton.icon(
                              onPressed: _exportLatest,
                              icon: const Icon(Icons.ios_share_outlined),
                              label: const Text('Encrypted .btbackup Export'),
                            ),
                            const SizedBox(height: 10),
                            OutlinedButton.icon(
                              onPressed: _importBackup,
                              icon: const Icon(Icons.file_download_outlined),
                              label: const Text('.btbackup Import Karein'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      AppFormSection(
                        english: 'Automatic Backup',
                        hindi: 'Rozana Copy',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Automatic Copy Chalu'),
                              subtitle: const Text(
                                'Roz 2 baje — charge + WiFi par',
                              ),
                              value: status.autoBackupEnabled,
                              onChanged: (value) async {
                                await metadata.setAutoBackupEnabled(value);
                                notifyBackupChanged(ref);
                              },
                            ),
                            if (status.autoBackupEnabled) ...[
                              const SizedBox(height: 8),
                              _FrequencyPicker(
                                value: status.autoFrequency,
                                onChanged: (value) async {
                                  await metadata.setAutoFrequency(value);
                                  notifyBackupChanged(ref);
                                },
                              ),
                            ],
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Sirf WiFi par'),
                              value: status.wifiOnly,
                              onChanged: (value) async {
                                await metadata.setWifiOnly(value);
                                notifyBackupChanged(ref);
                              },
                            ),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Sirf charge par'),
                              value: status.requireCharging,
                              onChanged: (value) async {
                                await metadata.setRequireCharging(value);
                                notifyBackupChanged(ref);
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      AppFormSection(
                        english: 'Data Encryption',
                        hindi: 'Data Suraksha',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.lock_outline,
                                  color: ColorPalette.purple,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  status.encryptionLabel,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Poora hisaab encrypted .btbackup file mein save hota hai. '
                              'Koi plain data phone ya cloud par nahi rakha jata.',
                              style: TextStyle(
                                fontSize: 13,
                                color: ColorPalette.labelSecondary,
                              ),
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final text = context.appText;
    return Row(
      children: [
        Icon(icon, color: ColorPalette.purple, size: 28),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: text.primaryBold.copyWith(fontSize: 18),
              ),
              Text(
                subtitle,
                style: text.secondary.copyWith(fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SetupEntryCard extends StatelessWidget {
  const _SetupEntryCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = context.appText;
    return Material(
      color: ColorPalette.cardSurface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ColorPalette.purple, width: 1.5),
          ),
          child: Row(
            children: [
              const Icon(Icons.backup_outlined, color: ColorPalette.purple, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Backup & Restore Setup',
                      style: text.primaryBold.copyWith(fontSize: 17),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Copy kahan save hogi — iCloud / manual export',
                      style: text.secondary.copyWith(fontSize: 14),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: ColorPalette.iconPrimary),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final text = context.appText;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: text.secondary.copyWith(fontSize: 14),
            ),
          ),
          Text(
            value,
            style: text.primaryBold.copyWith(fontSize: 14),
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
      selected: {value == AutoBackupFrequency.off ? AutoBackupFrequency.daily : value},
      onSelectionChanged: (selection) => onChanged(selection.first),
    );
  }
}