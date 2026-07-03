import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'assistant_language.dart';
import 'localization_service.dart';

const _assistantLanguageKey = 'assistant_language';
const _legacyLanguageKey = 'app_language';

/// Voice, greeting, AI, helper text, and notification language preference.
///
/// Never changes bilingual UI labels — see [LabelRegistry].
final assistantLanguageProvider = NotifierProvider<AssistantLanguageNotifier,
    AssistantLanguage>(AssistantLanguageNotifier.new);

/// @deprecated Use [assistantLanguageProvider].
final appLanguageProvider = assistantLanguageProvider;

/// Access to assistant copy bundles — not for primary UI labels.
final localizationServiceProvider = Provider<LocalizationService>(
  (ref) => LocalizationService.instance,
);

/// Voice AI locale — also used for future AI reply language selection.
final voiceLocaleProvider = Provider<String>((ref) {
  final language = ref.watch(assistantLanguageProvider);
  return ref.read(localizationServiceProvider).voiceLocale(language);
});

/// Alias for AI reply language — same locale as voice for now.
final aiReplyLocaleProvider = voiceLocaleProvider;

final class AssistantLanguageNotifier extends Notifier<AssistantLanguage> {
  @override
  AssistantLanguage build() {
    _restorePersisted();
    return AssistantLanguage.english;
  }

  Future<void> _restorePersisted() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = AssistantLanguage.fromCode(
          prefs.getString(_assistantLanguageKey),
        ) ??
        AssistantLanguage.fromCode(prefs.getString(_legacyLanguageKey));
    if (saved != null && saved.selectable && saved != state) {
      state = saved;
    }
  }

  Future<void> setAssistantLanguage(AssistantLanguage language) async {
    if (!language.selectable) return;

    state = language;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_assistantLanguageKey, language.code);
  }
}

/// @deprecated Use [AssistantLanguageNotifier.setAssistantLanguage].
extension AppLanguageNotifierCompat on AssistantLanguageNotifier {
  Future<void> setLanguage(AssistantLanguage language) =>
      setAssistantLanguage(language);
}
