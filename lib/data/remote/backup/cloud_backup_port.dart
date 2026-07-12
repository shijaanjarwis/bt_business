import 'dart:io';

/// Future-ready contract for Google Drive, iCloud, OneDrive, Dropbox, own cloud.
abstract interface class CloudBackupPort {
  Future<bool> isConnected();

  Future<String?> connectedAccountLabel();

  Future<void> uploadBackup(File backupFile);

  Future<List<CloudBackupRemoteEntry>> listRemoteBackups();

  Future<File> downloadBackup(String remoteId);
}

class CloudBackupRemoteEntry {
  const CloudBackupRemoteEntry({
    required this.remoteId,
    required this.createdAt,
    required this.sizeBytes,
  });

  final String remoteId;
  final DateTime createdAt;
  final int sizeBytes;
}

/// Local-only placeholder until a cloud provider is wired.
final class LocalCloudBackupPort implements CloudBackupPort {
  @override
  Future<bool> isConnected() async => false;

  @override
  Future<String?> connectedAccountLabel() async => null;

  @override
  Future<void> uploadBackup(File backupFile) async {
    throw UnsupportedError('Cloud backup is not connected yet');
  }

  @override
  Future<List<CloudBackupRemoteEntry>> listRemoteBackups() async => [];

  @override
  Future<File> downloadBackup(String remoteId) async {
    throw UnsupportedError('Cloud backup is not connected yet');
  }
}
