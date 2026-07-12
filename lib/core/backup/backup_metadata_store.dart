import 'package:shared_preferences/shared_preferences.dart';

import 'backup_format.dart';

/// Persists backup settings and status in SharedPreferences.
final class BackupMetadataStore {
  BackupMetadataStore(this._prefsFuture);

  static const _lastBackupAt = 'bt_last_backup_at';
  static const _autoFrequency = 'bt_auto_backup_frequency';
  static const _wifiOnly = 'bt_backup_wifi_only';
  static const _connectedAccount = 'bt_backup_connected_account';
  static const _lastError = 'bt_backup_last_error';
  static const _isRunning = 'bt_backup_is_running';

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
