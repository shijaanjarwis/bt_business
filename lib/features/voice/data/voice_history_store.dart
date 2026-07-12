import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Stores the last 20 voice commands for quick replay and correction.
final class VoiceHistoryStore {
  VoiceHistoryStore(this._prefsFuture);

  static const _historyKey = 'bt_voice_history';
  static const maxEntries = 20;

  final Future<SharedPreferences> _prefsFuture;

  static VoiceHistoryStore create() {
    return VoiceHistoryStore(SharedPreferences.getInstance());
  }

  Future<List<String>> readAll() async {
    final prefs = await _prefsFuture;
    final raw = prefs.getStringList(_historyKey);
    return raw ?? [];
  }

  Future<void> add(String transcript) async {
    final trimmed = transcript.trim();
    if (trimmed.isEmpty) return;

    final prefs = await _prefsFuture;
    final current = [...await readAll()];
    current.removeWhere((entry) => entry == trimmed);
    current.insert(0, trimmed);
    while (current.length > maxEntries) {
      current.removeLast();
    }
    await prefs.setStringList(_historyKey, current);
  }

  Future<void> clear() async {
    final prefs = await _prefsFuture;
    await prefs.remove(_historyKey);
  }

  Future<String> exportJson() async {
    return jsonEncode(await readAll());
  }
}
