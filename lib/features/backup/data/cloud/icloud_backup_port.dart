import 'dart:io';

import 'package:icloud_storage_plus/icloud_storage.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../../data/remote/backup/cloud_backup_port.dart';
import 'backup_cloud_constants.dart';

/// iOS zero-cost backup via the user's iCloud Drive container.
final class ICloudBackupPort implements CloudBackupPort {
  @override
  String get providerName => 'iCloud Drive';

  @override
  Future<bool> isAvailable() => ICloudStorage.icloudAvailable();

  @override
  Future<bool> isConnected() async => isAvailable();

  @override
  Future<String?> connectedAccountLabel() async {
    if (!await isAvailable()) return null;
    return 'iCloud Drive';
  }

  @override
  Future<void> ensureConnected() async {
    if (!await isAvailable()) {
      throw StateError('iCloud Drive available nahi hai. Settings mein iCloud on karein.');
    }
  }

  @override
  Future<String> uploadBackup(
    File backupFile, {
    required String remoteFileName,
  }) async {
    await ensureConnected();
    final cloudPath = '${BackupCloudConstants.icloudFolder}/$remoteFileName';
    await ICloudStorage.uploadFile(
      containerId: BackupCloudConstants.icloudContainerId,
      localPath: backupFile.path,
      cloudRelativePath: cloudPath,
    );
    return cloudPath;
  }

  @override
  Future<List<CloudBackupRemoteEntry>> listRemoteBackups() async {
    if (!await isAvailable()) return [];

    final items = await ICloudStorage.listContents(
      containerId: BackupCloudConstants.icloudContainerId,
      relativePath: '${BackupCloudConstants.icloudFolder}/',
    );

    final entries = <CloudBackupRemoteEntry>[];
    for (final item in items) {
      if (item.isDirectory) continue;
      final name = p.basename(item.relativePath);
      if (!name.endsWith('.btbackup')) continue;

      final metadata = await ICloudStorage.getItemMetadata(
        containerId: BackupCloudConstants.icloudContainerId,
        relativePath: item.relativePath,
      );

      entries.add(
        CloudBackupRemoteEntry(
          remoteId: item.relativePath,
          fileName: name,
          createdAt: metadata?.contentChangeDate ??
              metadata?.creationDate ??
              DateTime.now(),
          sizeBytes: metadata?.sizeInBytes ?? 0,
        ),
      );
    }

    entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return entries;
  }

  @override
  Future<File> downloadBackup(String remoteId) async {
    await ensureConnected();
    final tempDir = await getTemporaryDirectory();
    final localPath = p.join(
      tempDir.path,
      'icloud_${p.basename(remoteId)}',
    );
    await ICloudStorage.downloadFile(
      containerId: BackupCloudConstants.icloudContainerId,
      cloudRelativePath: remoteId,
      localPath: localPath,
    );
    return File(localPath);
  }

  @override
  Future<void> deleteRemoteBackup(String remoteId) async {
    await ensureConnected();
    await ICloudStorage.delete(
      containerId: BackupCloudConstants.icloudContainerId,
      relativePath: remoteId,
    );
  }
}
