import 'package:shared_preferences/shared_preferences.dart';

/// Persists which transactions currently have scheduled notifications.
final class ReminderScheduleTracker {
  ReminderScheduleTracker(this._prefsFuture);

  static const _key = 'bt_scheduled_reminder_tx_ids';

  final Future<SharedPreferences> _prefsFuture;

  static ReminderScheduleTracker create() {
    return ReminderScheduleTracker(SharedPreferences.getInstance());
  }

  Future<Set<String>> loadScheduledTransactionIds() async {
    final prefs = await _prefsFuture;
    return prefs.getStringList(_key)?.toSet() ?? {};
  }

  Future<void> saveScheduledTransactionIds(Set<String> ids) async {
    final prefs = await _prefsFuture;
    await prefs.setStringList(_key, ids.toList());
  }
}
