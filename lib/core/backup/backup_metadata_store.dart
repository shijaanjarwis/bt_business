import 'package:shared_preferences/shared_preferences.dart';

import 'backup_format.dart';

/// Persists backup settings and status in SharedPreferences.
final class BackupMetadataStore {
  BackupMetadataStore(this._prefsFuture);

  static const _lastBackupAt = 'bt_last_backup_at';
  static const _autoFrequency = 'bt_auto_backup_frequency';
  static const _wifiOnly = 'bt_backup_wifi_only';
  static const _requireCharging = 'bt_backup_require_charging';
  static const _autoBackupEnabled = 'bt_auto_backup_enabled';
  static const _autoBackupPromptShown = 'bt_auto_backup_prompt_shown';
  static const _connectedAccount = 'bt_backup_connected_account';
  static const _lastError = 'bt_backup_last_error';
  static const _isRunning = 'bt_backup_is_running';
  static const _storageChoice = 'bt_backup_storage_choice';
  static const _backupDetailsPrefix = 'bt_backup_details_';
  static const _lastFailedBackup = 'bt_last_failed_backup';

  final Future<SharedPreferences> _prefsFuture;

  static BackupMetadataStore create() {
    return BackupMetadataStore(SharedPreferences.getInstance());
  }

  Future<void> recordBackup(DateTime at) async {
    final prefs = await _prefsFuture;
    await prefs.setString(_lastBackupAt, at.toIso8601String());
    await prefs.remove(_lastError);
  }

  Future<DateTime?> lastBackupAt() async {
    final prefs = await _prefsFuture;
    final raw = prefs.getString(_lastBackupAt);
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  Future<void> setAutoFrequency(AutoBackupFrequency frequency) async {
    final prefs = await _prefsFuture;
    await prefs.setString(_autoFrequency, frequency.name);
  }

  Future<AutoBackupFrequency> autoFrequency() async {
    final prefs = await _prefsFuture;
    final raw = prefs.getString(_autoFrequency);
    if (raw == null) return AutoBackupFrequency.daily;
    return AutoBackupFrequency.values.byName(raw);
  }

  Future<void> setWifiOnly(bool value) async {
    final prefs = await _prefsFuture;
    await prefs.setBool(_wifiOnly, value);
  }

  Future<bool> wifiOnly() async {
    final prefs = await _prefsFuture;
    return prefs.getBool(_wifiOnly) ?? true;
  }

  Future<void> setRequireCharging(bool value) async {
    final prefs = await _prefsFuture;
    await prefs.setBool(_requireCharging, value);
  }

  Future<bool> requireCharging() async {
    final prefs = await _prefsFuture;
    return prefs.getBool(_requireCharging) ?? true;
  }

  Future<void> setAutoBackupEnabled(bool value) async {
    final prefs = await _prefsFuture;
    await prefs.setBool(_autoBackupEnabled, value);
  }

  Future<bool> autoBackupEnabled() async {
    final prefs = await _prefsFuture;
    return prefs.getBool(_autoBackupEnabled) ?? false;
  }

  Future<bool> autoBackupPromptShown() async {
    final prefs = await _prefsFuture;
    return prefs.getBool(_autoBackupPromptShown) ?? false;
  }

  Future<void> markAutoBackupPromptShown() async {
    final prefs = await _prefsFuture;
    await prefs.setBool(_autoBackupPromptShown, true);
  }

  String formatNextBackupLabel(DateTime? at) {
    if (at == null) return 'Band hai';
    return formatDisplayTimestamp(at);
  }

  Future<void> setConnectedAccount(String? label) async {
    final prefs = await _prefsFuture;
    if (label == null || label.isEmpty) {
      await prefs.remove(_connectedAccount);
    } else {
      await prefs.setString(_connectedAccount, label);
    }
  }

  Future<String?> connectedAccount() async {
    final prefs = await _prefsFuture;
    return prefs.getString(_connectedAccount);
  }

  Future<void> setLastError(String? message) async {
    final prefs = await _prefsFuture;
    if (message == null || message.isEmpty) {
      await prefs.remove(_lastError);
    } else {
      await prefs.setString(_lastError, message);
    }
  }

  Future<String?> lastError() async {
    final prefs = await _prefsFuture;
    return prefs.getString(_lastError);
  }

  Future<void> setRunning(bool value) async {
    final prefs = await _prefsFuture;
    await prefs.setBool(_isRunning, value);
  }

  Future<bool> isRunning() async {
    final prefs = await _prefsFuture;
    return prefs.getBool(_isRunning) ?? false;
  }

  Future<void> setStorageChoice(BackupStorageChoice choice) async {
    final prefs = await _prefsFuture;
    await prefs.setString(_storageChoice, choice.name);
  }

  Future<BackupStorageChoice> storageChoice() async {
    final prefs = await _prefsFuture;
    final raw = prefs.getString(_storageChoice);
    if (raw == null) return BackupStorageChoice.cloud;
    return BackupStorageChoice.values.byName(raw);
  }

  Future<void> recordBackupDetails({
    required String backupId,
    required String storageLocation,
    required bool cloudSynced,
    required bool succeeded,
  }) async {
    final prefs = await _prefsFuture;
    await prefs.setString(
      '$_backupDetailsPrefix$backupId',
      '$storageLocation|${cloudSynced ? 1 : 0}|${succeeded ? 1 : 0}',
    );
    if (succeeded) {
      await prefs.remove(_lastFailedBackup);
    }
  }

  Future<BackupDetailsRecord?> backupDetails(String backupId) async {
    final prefs = await _prefsFuture;
    final raw = prefs.getString('$_backupDetailsPrefix$backupId');
    if (raw == null) return null;
    final parts = raw.split('|');
    if (parts.length < 3) return null;
    return BackupDetailsRecord(
      storageLocation: parts[0],
      cloudSynced: parts[1] == '1',
      succeeded: parts[2] == '1',
    );
  }

  Future<void> recordFailedBackupAttempt({
    String storageLocation = 'Phone',
    String? errorMessage,
  }) async {
    final prefs = await _prefsFuture;
    final failedAt = DateTime.now().toIso8601String();
    final message = (errorMessage ?? '').replaceAll('|', ' ');
    await prefs.setString(_lastFailedBackup, '$failedAt|$storageLocation|$message');
  }

  Future<FailedBackupRecord?> lastFailedBackupAttempt() async {
    final prefs = await _prefsFuture;
    final raw = prefs.getString(_lastFailedBackup);
    if (raw == null) return null;
    final parts = raw.split('|');
    if (parts.length < 2) return null;
    return FailedBackupRecord(
      failedAt: DateTime.parse(parts[0]),
      storageLocation: parts[1],
      errorMessage: parts.length > 2 ? parts.sublist(2).join('|') : null,
    );
  }

  Future<Map<String, Object?>> exportAllPreferences() async {
    final prefs = await _prefsFuture;
    final exported = <String, Object?>{};
    for (final key in prefs.getKeys()) {
      final value = prefs.get(key);
      if (value is String) {
        exported[key] = value;
      } else if (value is bool) {
        exported[key] = value;
      } else if (value is int) {
        exported[key] = value;
      } else if (value is double) {
        exported[key] = value;
      } else if (value is List<String>) {
        exported[key] = value;
      }
    }
    return exported;
  }

  Future<void> importPreferences(Map<String, Object?> values) async {
    final prefs = await _prefsFuture;
    for (final entry in values.entries) {
      final value = entry.value;
      if (value is String) {
        await prefs.setString(entry.key, value);
      } else if (value is bool) {
        await prefs.setBool(entry.key, value);
      } else if (value is int) {
        await prefs.setInt(entry.key, value);
      } else if (value is double) {
        await prefs.setDouble(entry.key, value);
      } else if (value is List) {
        await prefs.setStringList(
          entry.key,
          value.map((item) => '$item').toList(),
        );
      }
    }
  }

  String formatLastBackupLabel(DateTime? at, DateTime reference) {
    if (at == null) return 'Kabhi Nahi';

    final backupDay = DateTime(at.year, at.month, at.day);
    final today = DateTime(reference.year, reference.month, reference.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (backupDay == today) return 'Aaj';
    if (backupDay == yesterday) return 'Kal';
    return '${at.day} ${_monthShort(at.month)}';
  }

  bool isStale(DateTime? at, DateTime reference) {
    if (at == null) return true;
    return reference.difference(at).inDays >= BackupFormat.staleDays;
  }

  bool isCritical(DateTime? at, DateTime reference) {
    if (at == null) return true;
    return reference.difference(at).inDays >= BackupFormat.criticalDays;
  }

  Future<void> recordCloudSync(DateTime at) async {
    final prefs = await _prefsFuture;
    await prefs.setString('bt_last_cloud_sync_at', at.toIso8601String());
  }

  String _monthShort(int month) {
    const labels = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return labels[month - 1];
  }

  String formatDisplayTimestamp(DateTime at) {
    final hour = at.hour % 12 == 0 ? 12 : at.hour % 12;
    final minute = at.minute.toString().padLeft(2, '0');
    final suffix = at.hour >= 12 ? 'PM' : 'AM';
    final now = DateTime.now();
    final day = DateTime(at.year, at.month, at.day);
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (day == today) {
      return 'Aaj $hour:$minute $suffix';
    }
    if (day == yesterday) {
      return 'Kal $hour:$minute $suffix';
    }
    return '${at.day} ${_monthShort(at.month)} $hour:$minute $suffix';
  }
}

class BackupDetailsRecord {
  const BackupDetailsRecord({
    required this.storageLocation,
    required this.cloudSynced,
    required this.succeeded,
  });

  final String storageLocation;
  final bool cloudSynced;
  final bool succeeded;
}

class FailedBackupRecord {
  const FailedBackupRecord({
    required this.failedAt,
    required this.storageLocation,
    this.errorMessage,
  });

  final DateTime failedAt;
  final String storageLocation;
  final String? errorMessage;
}
