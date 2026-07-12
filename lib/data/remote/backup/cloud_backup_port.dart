import 'dart:io';

/// Future-ready contract — iCloud Drive, Google Drive, or BT Business Cloud later.
abstract interface class CloudBackupPort {
  String get providerName;

  Future<bool> isAvailable();

  Future<bool> isConnected();

  Future<String?> connectedAccountLabel();

  /// Signs in or verifies platform cloud access before upload/restore.
  Future<void> ensureConnected();

  Future<String> uploadBackup(
    File backupFile, {
    required String remoteFileName,
  });

  Future<List<CloudBackupRemoteEntry>> listRemoteBackups();

  Future<File> downloadBackup(String remoteId);

  Future<void> deleteRemoteBackup(String remoteId);
}

class CloudBackupRemoteEntry {
  const CloudBackupRemoteEntry({
    required this.remoteId,
    required this.fileName,
    required this.createdAt,
    required this.sizeBytes,
  });

  final String remoteId;
  final String fileName;
  final DateTime createdAt;
  final int sizeBytes;
}

/// Offline fallback when platform cloud is unavailable (desktop / tests).
final class LocalCloudBackupPort implements CloudBackupPort {
  @override
  String get providerName => 'Local';

  @override
  Future<bool> isAvailable() async => false;

  @override
  Future<bool> isConnected() async => false;

  @override
  Future<String?> connectedAccountLabel() async => null;

  @override
  Future<void> ensureConnected() async {}

  @override
  Future<String> uploadBackup(
    File backupFile, {
    required String remoteFileName,
  }) async {
    return remoteFileName;
  }

  @override
  Future<List<CloudBackupRemoteEntry>> listRemoteBackups() async => [];

  @override
  Future<File> downloadBackup(String remoteId) async {
    throw UnsupportedError('Cloud backup is not available on this platform');
  }

  @override
  Future<void> deleteRemoteBackup(String remoteId) async {}
}

/// Reserved for future BT Business Cloud — engine stays unchanged.
final class BtBusinessCloudBackupPort implements CloudBackupPort {
  @override
  String get providerName => 'BT Business Cloud';

  @override
  Future<bool> isAvailable() async => false;

  @override
  Future<bool> isConnected() async => false;

  @override
  Future<String?> connectedAccountLabel() async => null;

  @override
  Future<void> ensureConnected() async {
    throw UnsupportedError('BT Business Cloud is not available yet');
  }

  @override
  Future<String> uploadBackup(
    File backupFile, {
    required String remoteFileName,
  }) async {
    throw UnsupportedError('BT Business Cloud is not available yet');
  }

  @override
  Future<List<CloudBackupRemoteEntry>> listRemoteBackups() async => [];

  @override
  Future<File> downloadBackup(String remoteId) async {
    throw UnsupportedError('BT Business Cloud is not available yet');
  }

  @override
  Future<void> deleteRemoteBackup(String remoteId) async {}
}
