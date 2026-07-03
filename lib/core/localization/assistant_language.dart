/// Assistant language for greeting, voice AI, AI replies, helpers, notifications.
///
/// Does NOT control on-screen UI labels — those are always English + daily Hindi
/// via [LabelRegistry] and [BilingualLabel].
enum AssistantLanguage {
  english('en', 'English', true),
  hindi('hi', 'Hindi', true),
  urdu('ur', 'Urdu', false);

  const AssistantLanguage(this.code, this.displayName, this.selectable);

  final String code;
  final String displayName;
  final bool selectable;

  bool get isComingSoon => !selectable;

  /// BCP-47 locale for voice AI and spoken assistant output.
  String get voiceLocaleCode => switch (this) {
        AssistantLanguage.english => 'en-IN',
        AssistantLanguage.hindi => 'hi-IN',
        AssistantLanguage.urdu => 'ur-PK',
      };

  String get assetFileName => '$code.json';

  static AssistantLanguage? fromCode(String? code) {
    if (code == null || code.isEmpty) return null;
    for (final language in AssistantLanguage.values) {
      if (language.code == code) return language;
    }
    return null;
  }
}

/// @deprecated Use [AssistantLanguage]. Kept for migration only.
typedef AppLanguage = AssistantLanguage;
