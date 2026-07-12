import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/backup/backup_format.dart';
import '../../../../core/backup/backup_metadata_store.dart';
import '../../../../core/backup/backup_providers.dart';
import '../../../../core/di/core_providers.dart';
import '../../../../core/di/data_revision.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_text_theme.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../shared/widgets/branding/developer_footer.dart';
import '../../../../shared/widgets/buttons/app_primary_button.dart';
import '../../../../shared/widgets/feedback/app_loading_view.dart';
import '../../../../shared/widgets/scaffold/app_register_app_bar.dart';
import '../widgets/backup_cloud_restore_sheet.dart';
import '../widgets/backup_history_card.dart';
import '../widgets/backup_preview_dialogs.dart';
import '../widgets/restore_source_sheet.dart';

/// Production Backup & Restore workflow — storage, preview, restore, history.
class BackupRestoreSetupPage extends ConsumerStatefulWidget {
  const BackupRestoreSetupPage({super.key});

  @override
  ConsumerState<BackupRestoreSetupPage> createState() =>
      _BackupRestoreSetupPageState();
}

class _BackupRestoreSetupPageState extends ConsumerState<BackupRestoreSetupPage> {
  bool _isWorking = false;
  String? _error;
  BackupStorageChoice? _selected;
  bool _loadedChoice = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadStoredChoice());
  }

  Future<void> _loadStoredChoice() async {
    final choice = await ref.read(backupMetadataStoreProvider).storageChoice();
    if (mounted) {
      setState(() {
        _selected = choice;
        _loadedChoice = true;
      });
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _isWorking = true;
      _error = null;
    });
    try {
      await action();
      notifyBackupChanged(ref);
      notifyDataChanged(ref);
    } catch (error) {
      setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _isWorking = false);
    }
  }

  Future<void> _selectStorage(BackupStorageChoice choice) async {
    await ref.read(backupMetadataStoreProvider).setStorageChoice(choice);
    setState(() => _selected = choice);
    notifyBackupChanged(ref);
  }

  Future<void> _backupWithPreview({required bool exportAfter}) async {
    final service = ref.read(backupServiceProvider);
    final preview = await service.buildCurrentBackupPreview();
    if (!mounted) return;

    final confirmed = await showBackupPreviewSheet(
      context,
      preview: preview,
      confirmLabel: exportAfter ? 'Export' : 'Backup',
    );
    if (!confirmed || !mounted) return;

    await _run(() async {
      await service.createBackup(type: BackupType.manual);
      if (exportAfter) {
        await service.exportLatestBackup();
      }
    });
  }

  Future<void> _restoreFromFile() async {
    final picked = await FilePicker.platform.pickFiles(
      allowedExtensions: ['btbackup'],
      type: FileType.custom,
    );
    if (picked == null || picked.files.isEmpty) return;
    final path = picked.files.single.path;
    if (path == null || !mounted) return;

    final service = ref.read(backupServiceProvider);
    final preview = await service.readFilePreview(path);
    if (!mounted) return;

    final confirmed = await showRestorePreviewDialog(context, preview: preview);
    if (!confirmed || !mounted) return;

    await _run(() async {
      await service.restoreImportedFile(path);
      ref.invalidate(appDatabaseProvider);
    });
  }

  Future<void> _restoreEntry(BackupEntry entry) async {
    final service = ref.read(backupServiceProvider);
    final preview = await service.readEntryPreview(entry);
    if (!mounted) return;

    final confirmed = await showRestorePreviewDialog(context, preview: preview);
    if (!confirmed || !mounted) return;

    await _run(() async {
      await service.restoreBackup(entry);
      ref.invalidate(appDatabaseProvider);
    });
  }

  Future<void> _connectCloud() async {
    await _run(() async {
      final cloud = ref.read(cloudBackupPortProvider);
      await cloud.ensureConnected();
      final account = await cloud.connectedAccountLabel();
      await ref.read(backupMetadataStoreProvider).setConnectedAccount(account);
    });
  }

  Future<void> _enableAutoBackup() async {
    final metadata = ref.read(backupMetadataStoreProvider);
    await metadata.setAutoBackupEnabled(true);
    await metadata.setAutoFrequency(AutoBackupFrequency.daily);
    notifyBackupChanged(ref);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final text = context.appText;
    final statusAsync = ref.watch(backupStatusProvider);
    final historyAsync = ref.watch(backupHistoryProvider);
    final metadata = ref.watch(backupMetadataStoreProvider);
    final isIos = Platform.isIOS;
    final cloudName = ref.watch(cloudBackupPortProvider).providerName;

    return Scaffold(
      backgroundColor: ColorPalette.background,
      appBar: const AppRegisterAppBar(
        english: 'Backup & Restore',
        hindi: 'Copy Suraksha',
      ),
      body: _isWorking || !_loadedChoice
          ? const AppLoadingView()
          : statusAsync.when(
              loading: () => const AppLoadingView(),
              error: (error, _) => Center(child: Text('$error', style: text.primary)),
              data: (status) {
                final choice = _selected ?? BackupStorageChoice.cloud;

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      'Aapka poora hisaab safe rakhein',
                      style: text.primaryBold.copyWith(fontSize: 20),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Encrypted .btbackup — AES-256. Koi plain data save nahi hota.',
                      style: text.secondary.copyWith(fontSize: 15, height: 1.45),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      _InlineError(message: _error!, text: text),
                    ],
                    const SizedBox(height: 16),
                    _StatusCard(text: text, status: status),
                    const SizedBox(height: 20),
                    Text('Backup', style: text.primaryBold.copyWith(fontSize: 17)),
                    const SizedBox(height: 10),
                    _StorageOptionCard(
                      text: text,
                      emoji: '☁️',
                      title: isIos ? 'iCloud Drive' : 'Google Drive',
                      subtitle: 'Recommended — roz automatic copy',
                      detail: isIos
                          ? 'iPhone ki iCloud par encrypted copy save hogi.'
                          : 'Google Drive par encrypted copy save hogi.',
                      recommended: true,
                      selected: choice == BackupStorageChoice.cloud,
                      onTap: () => _selectStorage(BackupStorageChoice.cloud),
                    ),
                    const SizedBox(height: 10),
                    _StorageOptionCard(
                      text: text,
                      emoji: '📁',
                      title: 'Export .btbackup File',
                      subtitle: 'Manual — khud save karein',
                      detail: 'Copy file banegi. WhatsApp, email ya Files se save karein.',
                      recommended: false,
                      selected: choice == BackupStorageChoice.manual,
                      onTap: () => _selectStorage(BackupStorageChoice.manual),
                    ),
                    const SizedBox(height: 12),
                    if (choice == BackupStorageChoice.cloud) ...[
                      _CloudPanel(
                        text: text,
                        status: status,
                        cloudName: cloudName,
                        isIos: isIos,
                        onConnect: _connectCloud,
                        onEnableAuto: _enableAutoBackup,
                        onBackup: () => _backupWithPreview(exportAfter: false),
                        onOpenSettings: openAppSettings,
                      ),
                    ] else ...[
                      AppPrimaryButton(
                        english: 'Create Backup',
                        hindi: 'Copy Banayein',
                        onPressed: () => _backupWithPreview(exportAfter: false),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton(
                        onPressed: () => _backupWithPreview(exportAfter: true),
                        child: Text('Export .btbackup', style: text.primaryBold),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Text('Restore', style: text.primaryBold.copyWith(fontSize: 17)),
                    const SizedBox(height: 10),
                    OutlinedButton(
                      onPressed: () => showRestoreSourceSheet(
                        context,
                        ref,
                        onRestoreFromFile: _restoreFromFile,
                        onRestoreFromCloud: () =>
                            showBackupCloudRestoreSheet(context, ref),
                      ),
                      child: Text('Wapas Laayein', style: text.primaryBold),
                    ),
                    const SizedBox(height: 20),
                    Text('Automatic Backup', style: text.primaryBold.copyWith(fontSize: 17)),
                    const SizedBox(height: 10),
                    _AutoBackupCard(
                      text: text,
                      status: status,
                      metadata: metadata,
                      onChanged: () => notifyBackupChanged(ref),
                    ),
                    const SizedBox(height: 20),
                    Text('Backup History', style: text.primaryBold.copyWith(fontSize: 17)),
                    const SizedBox(height: 10),
                    historyAsync.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.all(12),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (error, _) => Text('History load fail: $error', style: text.secondary),
                      data: (items) {
                        if (items.isEmpty) {
                          return Text('Abhi koi copy nahi bani.', style: text.secondary);
                        }
                        return Column(
                          children: items.map((item) {
                            final label = item.entry == null
                                ? 'Failed attempt'
                                : metadata.formatDisplayTimestamp(
                                    item.entry!.manifest.createdAt,
                                  );
                            return BackupHistoryCard(
                              text: text,
                              item: item,
                              dateLabel: label,
                              onRestore: item.entry == null
                                  ? null
                                  : () => _restoreEntry(item.entry!),
                              onShare: item.entry == null
                                  ? null
                                  : () => ref
                                      .read(backupServiceProvider)
                                      .exportBackup(item.entry!),
                              onDelete: item.entry == null
                                  ? null
                                  : () => _run(() => ref
                                      .read(backupServiceProvider)
                                      .deleteBackup(item.entry!)),
                            );
                          }).toList(),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: () => context.push(RouteNames.dataSafety),
                      child: Text('Advanced Data Safety', style: text.primaryBold),
                    ),
                    const DeveloperFooter(),
                  ],
                );
              },
            ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.text, required this.status});

  final AppTextTheme text;
  final BackupStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorPalette.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ColorPalette.border),
      ),
      child: Column(
        children: [
          _Row(text: text, label: 'Last Backup', value: status.lastBackupLabel),
          _Row(text: text, label: 'Next Scheduled', value: status.nextAutomaticBackupLabel),
          _Row(
            text: text,
            label: 'Backup Status',
            value: status.isRunning
                ? 'Chal rahi hai...'
                : status.lastError != null
                    ? 'Fail — ${status.lastError}'
                    : status.autoBackupEnabled
                        ? 'Automatic chalu'
                        : 'Manual',
          ),
          _Row(text: text, label: 'Encryption', value: status.encryptionLabel),
        ],
      ),
    );
  }
}

class _AutoBackupCard extends ConsumerWidget {
  const _AutoBackupCard({
    required this.text,
    required this.status,
    required this.metadata,
    required this.onChanged,
  });

  final AppTextTheme text;
  final BackupStatus status;
  final BackupMetadataStore metadata;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ColorPalette.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ColorPalette.border),
      ),
      child: Column(
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Daily automatic copy', style: text.primaryBold.copyWith(fontSize: 15)),
            subtitle: Text('Roz 2 baje', style: text.secondary.copyWith(fontSize: 13)),
            value: status.autoBackupEnabled,
            onChanged: (value) async {
              await metadata.setAutoBackupEnabled(value);
              if (value) await metadata.setAutoFrequency(AutoBackupFrequency.daily);
              onChanged();
            },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Only while charging', style: text.primary.copyWith(fontSize: 15)),
            value: status.requireCharging,
            onChanged: (value) async {
              await metadata.setRequireCharging(value);
              onChanged();
            },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Only on WiFi', style: text.primary.copyWith(fontSize: 15)),
            value: status.wifiOnly,
            onChanged: (value) async {
              await metadata.setWifiOnly(value);
              onChanged();
            },
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Cloud upload after successful backup',
                style: text.helper.copyWith(fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CloudPanel extends StatelessWidget {
  const _CloudPanel({
    required this.text,
    required this.status,
    required this.cloudName,
    required this.isIos,
    required this.onConnect,
    required this.onEnableAuto,
    required this.onBackup,
    required this.onOpenSettings,
  });

  final AppTextTheme text;
  final BackupStatus status;
  final String cloudName;
  final bool isIos;
  final VoidCallback onConnect;
  final VoidCallback onEnableAuto;
  final VoidCallback onBackup;
  final Future<bool> Function() onOpenSettings;

  @override
  Widget build(BuildContext context) {
    if (!status.isConnected) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ColorPalette.cardSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: ColorPalette.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('$cloudName set nahi hai', style: text.primaryBold.copyWith(fontSize: 16)),
            const SizedBox(height: 8),
            Text(
              isIos
                  ? '1. Settings kholein\n2. Apple ID > iCloud\n3. iCloud Drive ON karein\n4. Phir Try Karein'
                  : '1. Google account sign in karein\n2. Google Drive allow karein\n3. Phir Try Karein',
              style: text.secondary.copyWith(fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 12),
            AppPrimaryButton(
              english: 'Phir Try Karein',
              hindi: 'Cloud Check',
              onPressed: onConnect,
            ),
            const SizedBox(height: 10),
            OutlinedButton(onPressed: onOpenSettings, child: const Text('Settings Kholein')),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!status.autoBackupEnabled)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: OutlinedButton(
              onPressed: onEnableAuto,
              child: const Text('Automatic Copy Chalu Karein'),
            ),
          ),
        AppPrimaryButton(
          english: 'Create Backup',
          hindi: 'Copy Banayein',
          onPressed: onBackup,
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.text, required this.label, required this.value});

  final AppTextTheme text;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: text.secondary.copyWith(fontSize: 14))),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: text.primaryBold.copyWith(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class _StorageOptionCard extends StatelessWidget {
  const _StorageOptionCard({
    required this.text,
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.detail,
    required this.recommended,
    required this.selected,
    required this.onTap,
  });

  final AppTextTheme text;
  final String emoji;
  final String title;
  final String subtitle;
  final String detail;
  final bool recommended;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ColorPalette.cardSurface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? ColorPalette.purple : ColorPalette.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(title, style: text.primaryBold.copyWith(fontSize: 16)),
                        ),
                        if (recommended)
                          Text(
                            'Recommended',
                            style: text.caption.copyWith(
                              fontSize: 11,
                              color: ColorPalette.purple,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                      ],
                    ),
                    Text(subtitle, style: text.secondary.copyWith(fontSize: 14)),
                    Text(detail, style: text.helper.copyWith(fontSize: 13, height: 1.4)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message, required this.text});

  final String message;
  final AppTextTheme text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ColorPalette.destructive.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(message, style: text.primary.copyWith(color: ColorPalette.destructive)),
    );
  }
}
