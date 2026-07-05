import 'package:bt_business/core/localization/assistant_language.dart';
import 'package:bt_business/core/localization/dashboard_greeting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DashboardGreetingCopy regression guard', () {
    test('default style shows Assalamualaikum and Namaste on separate lines', () {
      const display = DashboardGreetingCopy.assalamualaikumNamaste;
      expect(display.primary, 'Assalamualaikum');
      expect(display.secondary, 'Namaste');
    });

    test('forStyle never returns forbidden greetings', () {
      for (final style in DashboardGreetingStyle.values) {
        for (final language in AssistantLanguage.values) {
          final display = DashboardGreetingCopy.forStyle(style, language: language);
          for (final banned in DashboardGreetingCopy.forbidden) {
            expect(display.primary.contains(banned), isFalse);
            expect(display.secondary?.contains(banned) ?? false, isFalse);
          }
        }
      }
    });

    test('english assistant language uses Assalamualaikum not Welcome', () {
      final display = DashboardGreetingCopy.forStyle(
        DashboardGreetingStyle.assalamualaikumNamaste,
      );
      expect(display.primary, 'Assalamualaikum');
      expect(display.secondary, 'Namaste');
      expect(display.primary, isNot('Welcome'));
    });
  });
}
