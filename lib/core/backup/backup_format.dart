/// Backup file format constants and manifest model.
abstract final class BackupFormat {
  static const magic = 'BTBT';
  static const version = 1;
  static const fileExtension = '.btbackup';
  static const maxHistoryCount = 30;
  static const staleDays = 7;
  static const criticalDays = 30;
  static const autoBackupHour = 2;
}

enum BackupType {
  manual,
  automatic,
  preRestore,
  imported,
}

enum AutoBackupFrequency {
  daily,
  weekly,
  monthly,
  off,
}

/// Lightweight manifest stored in plaintext at the start of each backup file.
class BackupManifest {
  const BackupManifest({
    required this.backupId,
    required this.businessId,
    required this.businessName,
    required this.createdAt,
    required this.schemaVersion,
    required this.appVersion,
    required this.type,
    required this.encryptedSize,
    required this.salt,
  });

  final String backupId;
  final String businessId;
  final String businessName;
  final DateTime createdAt;
  final int schemaVersion;
  final String appVersion;
  final BackupType type;
  final int encryptedSize;
  final String salt;

  Map<String, Object?> toJson() => {
        'backupId': backupId,
        'businessId': businessId,
        'businessName': businessName,
        'createdAt': createdAt.toIso8601String(),
        'schemaVersion': schemaVersion,
        'appVersion': appVersion,
        'type': type.name,
        'encryptedSize': encryptedSize,
        'salt': salt,
      };

  static BackupManifest fromJson(Map<String, Object?> json) {
    return BackupManifest(
      backupId: json['backupId']! as String,
      businessId: json['businessId']! as String,
      businessName: json['businessName']! as String,
      createdAt: DateTime.parse(json['createdAt']! as String),
      schemaVersion: json['schemaVersion']! as int,
      appVersion: json['appVersion']! as String,
      type: BackupType.values.byName(json['type']! as String),
      encryptedSize: json['encryptedSize']! as int,
      salt: json['salt']! as String,
    );
  }
}

/// One backup entry shown in restore history.
class BackupEntry {
  const BackupEntry({
    required this.id,
    required this.filePath,
    required this.manifest,
    required this.fileSizeBytes,
  });

  final String id;
  final String filePath;
  final BackupManifest manifest;
  final int fileSizeBytes;
}

/// Dashboard and settings backup status snapshot.
class BackupStatus {
  const BackupStatus({
    required this.lastBackupAt,
    required this.lastBackupLabel,
    required this.isConnected,
    required this.connectedAccountLabel,
    required this.cloudProviderName,
    required this.storageUsedBytes,
    required this.backupCount,
    required this.cloudBackupCount,
    required this.autoFrequency,
    required this.wifiOnly,
    required this.isStale,
    required this.isCritical,
    required this.isRunning,
    required this.lastError,
  });

  final DateTime? lastBackupAt;
  final String lastBackupLabel;
  final bool isConnected;
  final String connectedAccountLabel;
  final String cloudProviderName;
  final int storageUsedBytes;
  final int backupCount;
  final int cloudBackupCount;
  final AutoBackupFrequency autoFrequency;
  final bool wifiOnly;
  final bool isStale;
  final bool isCritical;
  final bool isRunning;
  final String? lastError;

  static const BackupStatus empty = BackupStatus(
    lastBackupAt: null,
    lastBackupLabel: 'Kabhi Nahi',
    isConnected: false,
    connectedAccountLabel: 'Connect nahi hai',
    cloudProviderName: 'Cloud',
    storageUsedBytes: 0,
    backupCount: 0,
    cloudBackupCount: 0,
    autoFrequency: AutoBackupFrequency.daily,
    wifiOnly: true,
    isStale: true,
    isCritical: true,
    isRunning: false,
    lastError: null,
  );
}
