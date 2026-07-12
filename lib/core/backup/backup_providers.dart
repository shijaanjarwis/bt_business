import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/remote/backup/cloud_backup_port.dart';
import '../di/core_providers.dart';
import 'backup_format.dart';
import 'backup_metadata_store.dart';
import 'backup_service.dart';

final backupMetadataStoreProvider = Provider<BackupMetadataStore>((ref) {
  return BackupMetadataStore.create();
});

final cloudBackupPortProvider = Provider<CloudBackupPort>((ref) {
  return LocalCloudBackupPort();
});

final backupServiceProvider = Provider<BackupService>((ref) {
  final database = ref.watch(appDatabaseProvider).requireValue;
  return BackupService(
    database: database,
    metadata: ref.watch(backupMetadataStoreProvider),
    cloud: ref.watch(cloudBackupPortProvider),
    logger: ref.watch(loggerProvider),
  );
});

final backupStatusProvider = FutureProvider.autoDispose<BackupStatus>((ref) async {
  ref.watch(backupRefreshProvider);
  return ref.watch(backupServiceProvider).getStatus();
});

final backupHistoryProvider = FutureProvider.autoDispose<List<BackupEntry>>((ref) async {
  ref.watch(backupRefreshProvider);
  return ref.watch(backupServiceProvider).listBackups();
});

/// Increment to refresh backup status and history.
final backupRefreshProvider = StateProvider<int>((ref) => 0);

void notifyBackupChanged(WidgetRef ref) {
  ref.read(backupRefreshProvider.notifier).state++;
}

void notifyBackupChangedFromRef(Ref ref) {
  ref.read(backupRefreshProvider.notifier).state++;
}
