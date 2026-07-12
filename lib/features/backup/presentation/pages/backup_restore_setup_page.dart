import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/backup/backup_format.dart';
import '../../../../core/backup/backup_providers.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_text_theme.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../shared/widgets/branding/developer_footer.dart';
import '../../../../shared/widgets/buttons/app_primary_button.dart';
import '../../../../shared/widgets/feedback/app_loading_view.dart';
import '../../../../shared/widgets/scaffold/app_register_app_bar.dart';
import '../widgets/backup_cloud_restore_sheet.dart';

/// Backup & Restore setup — storage choice, cloud guide, first backup.
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

  Future<void> _createBackup() {
    return _run(() async {
      await ref.read(backupServiceProvider).createBackup(type: BackupType.manual);
    });
  }

  Future<void> _exportLatest() {
    return _run(() async {
      await ref.read(backupServiceProvider).exportLatestBackup();
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
              error: (error, _) => _ErrorBody(message: '$error', text: text),
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
                      'Pehle batayein copy kahan save hogi. '
                      'Poora data encrypted .btbackup file mein rahega.',
                      style: text.secondary.copyWith(fontSize: 15, height: 1.45),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      _InlineError(message: _error!, text: text),
                    ],
                    const SizedBox(height: 20),
                    Text(
                      'Copy kahan save karein?',
                      style: text.primaryBold.copyWith(fontSize: 17),
                    ),
                    const SizedBox(height: 10),
                    _StorageOptionCard(
                      text: text,
                      title: isIos ? 'iCloud Drive' : 'Google Drive',
                      subtitle: isIos
                          ? 'Recommended — roz automatic copy'
                          : 'Recommended — roz automatic copy',
                      detail: isIos
                          ? 'iPhone ki iCloud par encrypted copy save hogi. '
                              'Naya phone par wapas la sakte hain.'
                          : 'Google Drive par encrypted copy save hogi. '
                              'Naya phone par wapas la sakte hain.',
                      icon: Icons.cloud_outlined,
                      recommended: true,
                      selected: choice == BackupStorageChoice.cloud,
                      onTap: () => _selectStorage(BackupStorageChoice.cloud),
                    ),
                    const SizedBox(height: 10),
                    _StorageOptionCard(
                      text: text,
                      title: 'Export manually',
                      subtitle: '.btbackup file — khud save karein',
                      detail: 'Copy file banegi. Aap WhatsApp, email ya '
                          'Files app se kahin bhi save kar sakte hain.',
                      icon: Icons.ios_share_outlined,
                      recommended: false,
                      selected: choice == BackupStorageChoice.manual,
                      onTap: () => _selectStorage(BackupStorageChoice.manual),
                    ),
                    const SizedBox(height: 20),
                    if (choice == BackupStorageChoice.cloud) ...[
                      _CloudSetupPanel(
                        text: text,
                        status: status,
                        cloudName: cloudName,
                        isIos: isIos,
                        onConnect: _connectCloud,
                        onEnableAuto: _enableAutoBackup,
                        onBackupNow: _createBackup,
                        onOpenSettings: openAppSettings,
                        onRestoreCloud: () =>
                            showBackupCloudRestoreSheet(context, ref),
                      ),
                    ] else ...[
                      _ManualSetupPanel(
                        text: text,
                        lastBackupLabel: status.lastBackupLabel,
                        onBackupNow: _createBackup,
                        onExport: _exportLatest,
                        onOpenDataSafety: () => context.push(RouteNames.dataSafety),
                      ),
                    ],
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: () => context.push(RouteNames.dataSafety),
                      child: Text(
                        'Poori Data Safety Settings',
                        style: text.primaryBold.copyWith(fontSize: 15),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Aakhri copy: ${status.lastBackupLabel} • '
                      '${status.backupCount} copies phone par',
                      style: text.caption.copyWith(fontSize: 13),
                    ),
                    const DeveloperFooter(),
                  ],
                );
              },
            ),
    );
  }
}

class _CloudSetupPanel extends StatelessWidget {
  const _CloudSetupPanel({
    required this.text,
    required this.status,
    required this.cloudName,
    required this.isIos,
    required this.onConnect,
    required this.onEnableAuto,
    required this.onBackupNow,
    required this.onOpenSettings,
    required this.onRestoreCloud,
  });

  final AppTextTheme text;
  final BackupStatus status;
  final String cloudName;
  final bool isIos;
  final VoidCallback onConnect;
  final VoidCallback onEnableAuto;
  final VoidCallback onBackupNow;
  final Future<bool> Function() onOpenSettings;
  final VoidCallback onRestoreCloud;

  @override
  Widget build(BuildContext context) {
    final cloudReady = status.isConnected;

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
          Text(
            '$cloudName Setup',
            style: text.primaryBold.copyWith(fontSize: 17),
          ),
          const SizedBox(height: 8),
          if (cloudReady) ...[
            Row(
              children: [
                const Icon(Icons.check_circle_outline,
                    color: ColorPalette.accentGreen, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${status.connectedAccountLabel} — tayyar hai',
                    style: text.primary.copyWith(fontSize: 15),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (!status.autoBackupEnabled) ...[
              Text(
                'Automatic copy abhi band hai. Chalu karein taaki roz raat '
                '2 baje WiFi + charge par copy ban jaye.',
                style: text.secondary.copyWith(fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 10),
              FilledButton(
                onPressed: onEnableAuto,
                child: const Text('Automatic Copy Chalu Karein'),
              ),
              const SizedBox(height: 10),
            ] else ...[
              Text(
                'Automatic copy chalu — ${status.nextAutomaticBackupLabel}',
                style: text.secondary.copyWith(fontSize: 14),
              ),
              const SizedBox(height: 10),
            ],
            AppPrimaryButton(
              english: 'Abhi Copy Banayein',
              hindi: 'Pehli Copy',
              onPressed: onBackupNow,
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: onRestoreCloud,
              child: const Text('Cloud Se Wapas Laayein'),
            ),
          ] else ...[
            Text(
              '$cloudName abhi set nahi hai.',
              style: text.primaryBold.copyWith(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              isIos
                  ? '1. Settings kholein\n'
                      '2. Apple ID par tap karein\n'
                      '3. iCloud > iCloud Drive ON karein\n'
                      '4. Wapas aakar "Phir Try Karein" dabayein'
                  : '1. Phone par Google account sign in karein\n'
                      '2. Google Drive access allow karein\n'
                      '3. Wapas aakar "Phir Try Karein" dabayein',
              style: text.secondary.copyWith(fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 12),
            AppPrimaryButton(
              english: 'Phir Try Karein',
              hindi: 'Cloud Check',
              onPressed: onConnect,
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: onOpenSettings,
              child: const Text('Settings Kholein'),
            ),
          ],
        ],
      ),
    );
  }
}

class _ManualSetupPanel extends StatelessWidget {
  const _ManualSetupPanel({
    required this.text,
    required this.lastBackupLabel,
    required this.onBackupNow,
    required this.onExport,
    required this.onOpenDataSafety,
  });

  final AppTextTheme text;
  final String lastBackupLabel;
  final VoidCallback onBackupNow;
  final VoidCallback onExport;
  final VoidCallback onOpenDataSafety;

  @override
  Widget build(BuildContext context) {
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
          Text(
            'Manual Export',
            style: text.primaryBold.copyWith(fontSize: 17),
          ),
          const SizedBox(height: 8),
          Text(
            'Pehle phone par copy banegi. Phir .btbackup file export karke '
            'kahin safe jagah save karein.',
            style: text.secondary.copyWith(fontSize: 14, height: 1.45),
          ),
          const SizedBox(height: 8),
          Text(
            'Aakhri copy: $lastBackupLabel',
            style: text.primary.copyWith(fontSize: 15),
          ),
          const SizedBox(height: 12),
          AppPrimaryButton(
            english: 'Abhi Copy Banayein',
            hindi: 'Phone Par Copy',
            onPressed: onBackupNow,
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: onExport,
            child: const Text('Encrypted .btbackup Export'),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: onOpenDataSafety,
            child: const Text('.btbackup Se Wapas Laayein'),
          ),
        ],
      ),
    );
  }
}

class _StorageOptionCard extends StatelessWidget {
  const _StorageOptionCard({
    required this.text,
    required this.title,
    required this.subtitle,
    required this.detail,
    required this.icon,
    required this.recommended,
    required this.selected,
    required this.onTap,
  });

  final AppTextTheme text;
  final String title;
  final String subtitle;
  final String detail;
  final IconData icon;
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
              Icon(icon, color: ColorPalette.purple, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: text.primaryBold.copyWith(fontSize: 16),
                          ),
                        ),
                        if (recommended)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: ColorPalette.purple.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Recommended',
                              style: text.caption.copyWith(
                                fontSize: 11,
                                color: ColorPalette.purple,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: text.secondary.copyWith(fontSize: 14),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      detail,
                      style: text.helper.copyWith(fontSize: 13, height: 1.4),
                    ),
                  ],
                ),
              ),
              if (selected)
                const Padding(
                  padding: EdgeInsets.only(left: 8, top: 2),
                  child: Icon(
                    Icons.check_circle_rounded,
                    color: ColorPalette.purple,
                    size: 22,
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
        border: Border.all(color: ColorPalette.destructive.withValues(alpha: 0.3)),
      ),
      child: Text(
        message,
        style: text.primary.copyWith(
          fontSize: 14,
          color: ColorPalette.destructive,
        ),
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message, required this.text});

  final String message;
  final AppTextTheme text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text('Load nahi ho paya', style: text.primaryBold.copyWith(fontSize: 18)),
          const SizedBox(height: 8),
          Text(message, style: text.secondary),
        ],
      ),
    );
  }
}
