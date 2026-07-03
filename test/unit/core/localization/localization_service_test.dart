import 'package:bt_business/core/localization/assistant_language.dart';
import 'package:bt_business/core/localization/greeting_copy.dart';
import 'package:bt_business/core/localization/label_registry.dart';
import 'package:bt_business/core/localization/localization_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await LocalizationService.instance.ensureLoaded();
  });

  test('greeting follows assistant language via GreetingCopy', () {
    final service = LocalizationService.instance;

    expect(
      service.greeting(AssistantLanguage.english),
      GreetingCopy.english,
    );
    expect(
      service.greeting(AssistantLanguage.hindi),
      GreetingCopy.hindi,
    );
    expect(
      service.greeting(AssistantLanguage.urdu),
      GreetingCopy.urdu,
    );
  });

  test('label registry is always bilingual english plus daily hindi', () {
    expect(LabelRegistry.sale.english, 'Sale');
    expect(LabelRegistry.sale.hindi, 'Bikri');
    expect(LabelRegistry.item.hindi, 'Maal');
    expect(LabelRegistry.cash.hindi, 'Cash');
    expect(LabelRegistry.party.hindi, 'Party');
  });

  test('voice and AI locale is ready for assistant features', () {
    expect(AssistantLanguage.english.voiceLocaleCode, 'en-IN');
    expect(AssistantLanguage.hindi.voiceLocaleCode, 'hi-IN');
    expect(AssistantLanguage.urdu.voiceLocaleCode, 'ur-PK');
  });

  test('assistant helper clarifies UI stays bilingual', () {
    final service = LocalizationService.instance;
    expect(
      service.helper(AssistantLanguage.english, 'settings_assistant_helper'),
      contains('Screen labels always stay English'),
    );
  });
}
