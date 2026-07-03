import 'package:bt_business/core/localization/assistant_language.dart';
import 'package:bt_business/core/localization/greeting_copy.dart';
import 'package:bt_business/core/localization/localization_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GreetingCopy regression guard', () {
    test('approved greetings per assistant language', () {
      expect(GreetingCopy.forLanguage(AssistantLanguage.english),
          'Assalamu Alaikum / Namaste');
      expect(GreetingCopy.forLanguage(AssistantLanguage.hindi),
          'अस्सलामु अलैकुम / नमस्ते');
      expect(GreetingCopy.forLanguage(AssistantLanguage.urdu), 'السلام علیکم');
    });

    test('forbidden generic greetings are never approved copy', () {
      for (final language in AssistantLanguage.values) {
        final greeting = GreetingCopy.forLanguage(language);
        for (final banned in GreetingCopy.forbidden) {
          expect(
            greeting.contains(banned),
            isFalse,
            reason: '$language greeting must not contain "$banned"',
          );
        }
      }
    });

    test('LocalizationService greeting uses approved copy not Welcome', () {
      final service = LocalizationService.instance;

      for (final language in AssistantLanguage.values) {
        expect(service.greeting(language), GreetingCopy.forLanguage(language));
      }

      expect(service.greeting(AssistantLanguage.english), isNot('Welcome'));
    });
  });
}
