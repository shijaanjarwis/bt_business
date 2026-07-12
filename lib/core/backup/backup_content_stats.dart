/// Record counts embedded in backup manifest for preview screens.
class BackupContentStats {
  const BackupContentStats({
    this.databaseSizeBytes = 0,
    this.partyCount = 0,
    this.itemCount = 0,
    this.saleCount = 0,
    this.purchaseCount = 0,
    this.expenseCount = 0,
    this.ledgerEntryCount = 0,
  });

  final int databaseSizeBytes;
  final int partyCount;
  final int itemCount;
  final int saleCount;
  final int purchaseCount;
  final int expenseCount;
  final int ledgerEntryCount;

  int get transactionCount => saleCount + purchaseCount + expenseCount;

  Map<String, Object?> toJson() => {
        'databaseSizeBytes': databaseSizeBytes,
        'partyCount': partyCount,
        'itemCount': itemCount,
        'saleCount': saleCount,
        'purchaseCount': purchaseCount,
        'expenseCount': expenseCount,
        'ledgerEntryCount': ledgerEntryCount,
      };

  static BackupContentStats fromJson(Map<String, Object?>? json) {
    if (json == null) return const BackupContentStats();
    return BackupContentStats(
      databaseSizeBytes: json['databaseSizeBytes'] as int? ?? 0,
      partyCount: json['partyCount'] as int? ?? 0,
      itemCount: json['itemCount'] as int? ?? 0,
      saleCount: json['saleCount'] as int? ?? 0,
      purchaseCount: json['purchaseCount'] as int? ?? 0,
      expenseCount: json['expenseCount'] as int? ?? 0,
      ledgerEntryCount: json['ledgerEntryCount'] as int? ?? 0,
    );
  }

  static const BackupContentStats empty = BackupContentStats();
}

/// UI-facing backup preview — current data or saved backup file.
class BackupPreviewData {
  const BackupPreviewData({
    required this.backupDate,
    required this.backupTimeLabel,
    required this.appVersion,
    required this.businessName,
    required this.fileSizeBytes,
    required this.stats,
    this.storageLocation,
    this.isExistingBackup = false,
  });

  final DateTime backupDate;
  final String backupTimeLabel;
  final String appVersion;
  final String businessName;
  final int fileSizeBytes;
  final BackupContentStats stats;
  final String? storageLocation;
  final bool isExistingBackup;
}

enum BackupHistoryStatus {
  success,
  failed,
}

enum BackupStorageLocation {
  phone,
  cloud,
  phoneAndCloud,
  exportFile,
}

extension BackupStorageLocationLabel on BackupStorageLocation {
  String get label => switch (this) {
        BackupStorageLocation.phone => 'Phone',
        BackupStorageLocation.cloud => 'Cloud',
        BackupStorageLocation.phoneAndCloud => 'Phone + Cloud',
        BackupStorageLocation.exportFile => 'Export File',
      };
}
