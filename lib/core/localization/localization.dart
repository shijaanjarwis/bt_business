/// Multilingual foundation for BT Business.
///
/// **Bilingual UI (permanent):** English label + daily spoken Hindi subtitle
/// on every screen via [LabelRegistry] and [BilingualLabel]. This never
/// changes with settings.
///
/// **Assistant language:** Greeting, voice AI, AI replies, helper text,
/// and notifications — controlled by [assistantLanguageProvider].
library;

export 'assistant_language.dart';
export 'label_registry.dart';
export 'language_provider.dart';
export 'localization_service.dart';
