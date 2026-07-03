import 'assistant_language.dart';

/// Approved dashboard greetings — single source of truth.
///
/// Never use time-of-day or generic greetings (Welcome, Good Morning, etc.).
abstract final class GreetingCopy {
  static const String english = 'Assalamu Alaikum / Namaste';
  static const String hindi = 'अस्सलामु अलैकुम / नमस्ते';
  static const String urdu = 'السلام علیکم';

  /// Greetings that must never appear in the product.
  static const List<String> forbidden = [
    'Welcome',
    'Good Morning',
    'Good Afternoon',
    'Good Evening',
  ];

  static String forLanguage(AssistantLanguage language) {
    return switch (language) {
      AssistantLanguage.english => english,
      AssistantLanguage.hindi => hindi,
      AssistantLanguage.urdu => urdu,
    };
  }
}
