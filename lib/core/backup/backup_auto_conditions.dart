import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'backup_format.dart';
import 'backup_metadata_store.dart';

/// Checks whether automatic backup conditions are met — WiFi and charging.
final class BackupAutoConditions {
  BackupAutoConditions({
    Connectivity? connectivity,
    Battery? battery,
    BackupMetadataStore? metadata,
  })  : _connectivity = connectivity ?? Connectivity(),
        _battery = battery ?? Battery(),
        _metadata = metadata ?? BackupMetadataStore.create();

  final Connectivity _connectivity;
  final Battery _battery;
  final BackupMetadataStore _metadata;

  Future<bool> canRunAutomaticBackup() async {
    if (!await _metadata.autoBackupEnabled()) return false;
    if (!await _networkAllowed()) return false;
    if (await _metadata.requireCharging() && !await _isCharging()) {
      return false;
    }
    return true;
  }

  Future<bool> _networkAllowed() async {
    final results = await _connectivity.checkConnectivity();
    if (results.contains(ConnectivityResult.none)) return false;

    final wifiOnly = await _metadata.wifiOnly();
    if (!wifiOnly) return true;

    return results.contains(ConnectivityResult.wifi) ||
        results.contains(ConnectivityResult.ethernet);
  }

  Future<bool> _isCharging() async {
    final state = await _battery.batteryState;
    return state == BatteryState.charging || state == BatteryState.full;
  }
}

/// Computes the next scheduled automatic backup window.
DateTime? computeNextAutomaticBackup({
  required DateTime reference,
  required bool autoEnabled,
  required AutoBackupFrequency frequency,
  DateTime? lastBackupAt,
}) {
  if (!autoEnabled || frequency == AutoBackupFrequency.off) return null;

  DateTime candidate = DateTime(
    reference.year,
    reference.month,
    reference.day,
    BackupFormat.autoBackupHour,
  );

  if (!reference.isBefore(candidate)) {
    candidate = candidate.add(const Duration(days: 1));
  }

  if (lastBackupAt == null) return candidate;

  switch (frequency) {
    case AutoBackupFrequency.daily:
      return candidate;
    case AutoBackupFrequency.weekly:
      while (candidate.difference(lastBackupAt).inDays < 7) {
        candidate = candidate.add(const Duration(days: 1));
      }
      return candidate;
    case AutoBackupFrequency.monthly:
      while (candidate.month == lastBackupAt.month &&
          candidate.year == lastBackupAt.year) {
        candidate = candidate.add(const Duration(days: 1));
      }
      return candidate;
    case AutoBackupFrequency.off:
      return null;
  }
}
