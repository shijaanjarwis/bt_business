import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../domain/voice_draft.dart';
import '../../domain/voice_intent_type.dart';
import '../../domain/voice_memory.dart';

/// On-device business memory — never leaves the phone.
final class VoiceBusinessMemoryStore {
  VoiceBusinessMemoryStore(this._prefsFuture);

  static const _storageKey = 'bt_voice_business_memory';
  static const maxPatterns = 50;

  final Future<SharedPreferences> _prefsFuture;
  final Uuid _uuid = const Uuid();

  static VoiceBusinessMemoryStore create() {
    return VoiceBusinessMemoryStore(SharedPreferences.getInstance());
  }

  Future<List<VoiceMemoryPattern>> readAll() async {
    final prefs = await _prefsFuture;
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return [];

    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((entry) => VoiceMemoryPattern.fromJson(Map<String, Object?>.from(entry as Map)))
        .toList();
  }

  Future<void> _writeAll(List<VoiceMemoryPattern> patterns) async {
    final prefs = await _prefsFuture;
    final encoded = jsonEncode(patterns.map((p) => p.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }

  Future<void> learnFromDraft(VoiceDraft draft) async {
    if (!_shouldLearn(draft.intent)) return;

    final patterns = await readAll();
    final party = draft.partyName?.trim();
    final item = draft.itemName?.trim();
    final channel = primaryPaymentChannel(draft.paymentBreakdown);

    final existingIndex = patterns.indexWhere(
      (pattern) =>
          pattern.intent == draft.intent &&
          _same(party, pattern.partyName) &&
          _same(item, pattern.itemName),
    );

    if (existingIndex >= 0) {
      final updated = patterns[existingIndex].bumpUsage(
        unit: draft.unit ?? patterns[existingIndex].unit,
        rate: draft.rate ?? patterns[existingIndex].rate,
        primaryPaymentChannel: channel ?? patterns[existingIndex].primaryPaymentChannel,
        reminderDay: draft.reminderDate?.day ?? patterns[existingIndex].reminderDay,
        notes: draft.notes ?? patterns[existingIndex].notes,
      );
      patterns.removeAt(existingIndex);
      patterns.insert(0, updated);
    } else {
      patterns.insert(
        0,
        VoiceMemoryPattern(
          id: _uuid.v4(),
          intent: draft.intent,
          partyName: party,
          itemName: item,
          unit: draft.unit,
          rate: draft.rate,
          primaryPaymentChannel: channel,
          reminderDay: draft.reminderDate?.day,
          notes: draft.notes,
          useCount: 1,
          lastUsedAt: DateTime.now(),
        ),
      );
    }

    while (patterns.length > maxPatterns) {
      patterns.removeLast();
    }

    await _writeAll(patterns);
  }

  VoiceMemoryPattern? findLastForParty(
    String partyName, {
    VoiceIntentType? intent,
  }) {
    return _syncFind(
      (pattern) =>
          _same(pattern.partyName, partyName) &&
          (intent == null || pattern.intent == intent),
    );
  }

  VoiceMemoryPattern? findPartyItemContext({
    required String partyName,
    required VoiceIntentType intent,
  }) {
    return _syncFind(
      (pattern) =>
          _same(pattern.partyName, partyName) &&
          pattern.intent == intent &&
          pattern.itemName != null &&
          pattern.itemName!.isNotEmpty,
    );
  }

  VoiceMemoryPattern? findRateFor({
    required String partyName,
    String? itemName,
    VoiceIntentType intent = VoiceIntentType.sale,
  }) {
    if (itemName != null && itemName.isNotEmpty) {
      final exact = _syncFind(
        (pattern) =>
            _same(pattern.partyName, partyName) &&
            _same(pattern.itemName, itemName) &&
            pattern.intent == intent &&
            pattern.rate != null &&
            pattern.rate! > 0,
      );
      if (exact != null) return exact;
    }

    return _syncFind(
      (pattern) =>
          _same(pattern.partyName, partyName) &&
          pattern.intent == intent &&
          pattern.rate != null &&
          pattern.rate! > 0,
    );
  }

  VoiceMemoryPattern? findMostUsedParty() {
    final patterns = _cached;
    if (patterns.isEmpty) return null;

    final scored = <String, VoiceMemoryPattern>{};
    for (final pattern in patterns) {
      final party = pattern.partyName;
      if (party == null || party.isEmpty) continue;
      final key = party.toLowerCase();
      final existing = scored[key];
      if (existing == null || pattern.useCount > existing.useCount) {
        scored[key] = pattern;
      }
    }
    if (scored.isEmpty) return null;
    return scored.values.reduce(
      (a, b) => a.useCount >= b.useCount ? a : b,
    );
  }

  List<VoiceMemoryPattern> _cached = [];

  Future<void> warmCache() async {
    _cached = await readAll();
  }

  VoiceMemoryPattern? _syncFind(bool Function(VoiceMemoryPattern) test) {
    for (final pattern in _cached) {
      if (test(pattern)) return pattern;
    }
    return null;
  }

  bool _shouldLearn(VoiceIntentType intent) {
    return switch (intent) {
      VoiceIntentType.sale ||
      VoiceIntentType.purchase ||
      VoiceIntentType.paymentReceived ||
      VoiceIntentType.paymentPaid ||
      VoiceIntentType.expense =>
        true,
      _ => false,
    };
  }

  bool _same(String? a, String? b) {
    if (a == null || b == null) return false;
    return a.trim().toLowerCase() == b.trim().toLowerCase();
  }
}
