import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Temporarily hides snoozed reminders from grouped notifications.
final class ReminderSnoozeStore {
  ReminderSnoozeStore(this._prefsFuture);

  static const _key = 'bt_reminder_snooze_until';

  final Future<SharedPreferences> _prefsFuture;

  static ReminderSnoozeStore create() {
    return ReminderSnoozeStore(SharedPreferences.getInstance());
  }

  Future<Map<String, String>> _loadAll() async {
    final prefs = await _prefsFuture;
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return {};
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return {};
    return decoded.map((key, value) => MapEntry('$key', '$value'));
  }

  Future<void> _saveAll(Map<String, String> values) async {
    final prefs = await _prefsFuture;
    await prefs.setString(_key, jsonEncode(values));
  }

  Future<void> snoozeUntil(String transactionId, DateTime until) async {
    final all = await _loadAll();
    all[transactionId] = until.toIso8601String();
    await _saveAll(all);
  }

  Future<bool> isSnoozed(String transactionId, DateTime now) async {
    final all = await _loadAll();
    final iso = all[transactionId];
    if (iso == null) return false;
    final until = DateTime.tryParse(iso);
    if (until == null) return false;
    if (!until.isAfter(now)) {
      all.remove(transactionId);
      await _saveAll(all);
      return false;
    }
    return true;
  }

  Future<void> clear(String transactionId) async {
    final all = await _loadAll();
    if (all.remove(transactionId) != null) {
      await _saveAll(all);
    }
  }
}
