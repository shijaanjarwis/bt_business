import 'dart:convert';

import 'package:flutter/services.dart';

import 'assistant_language.dart';
import 'greeting_copy.dart';

/// Loads assistant copy — greeting, helpers, AI, notifications.
///
/// **Permanent rule:** UI labels are NEVER translated here.
/// Every screen uses [LabelRegistry] + [BilingualLabel]:
/// English on top, daily spoken Hindi in parentheses below.
final class LocalizationService {
  LocalizationService._();

  static final LocalizationService instance = LocalizationService._();

  final Map<AssistantLanguage, Map<String, String>> _strings = {};
  Future<void>? _loadFuture;

  Future<void> ensureLoaded() {
    _loadFuture ??= _loadAll();
    return _loadFuture!;
  }

  Future<void> _loadAll() async {
    for (final language in AssistantLanguage.values) {
      final raw = await rootBundle.loadString(
        'assets/localization/${language.assetFileName}',
      );
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      _strings[language] = decoded.map(
        (key, value) => MapEntry(key, value.toString()),
      );
    }
  }

  /// Assistant copy only — never used for primary UI labels.
  String translate(
    AssistantLanguage language,
    String key, {
    String? fallback,
  }) {
    final localized = _strings[language]?[key];
    if (localized != null && localized.isNotEmpty) return localized;

    final english = _strings[AssistantLanguage.english]?[key];
    if (english != null && english.isNotEmpty) return english;

    return fallback ?? key;
  }

  /// Approved dashboard greeting — not loaded from JSON to prevent copy drift.
  String greeting(AssistantLanguage language) => GreetingCopy.forLanguage(language);

  String helper(AssistantLanguage language, String key) =>
      translate(language, key);

  String voiceLocale(AssistantLanguage language) => language.voiceLocaleCode;

  String assistantOptionTitle(AssistantLanguage language) => translate(
        AssistantLanguage.english,
        'assistant_option_${language.code}',
      );

  String assistantOptionSubtitle(AssistantLanguage language) => translate(
        AssistantLanguage.english,
        'assistant_option_${language.code}_subtitle',
      );
}
