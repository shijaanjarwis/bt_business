import 'package:bt_business/core/localization/assistant_language.dart';
import 'package:bt_business/core/localization/dashboard_greeting.dart';
import 'package:bt_business/core/localization/dashboard_greeting_provider.dart';
import 'package:bt_business/core/localization/label_registry.dart';
import 'package:bt_business/core/localization/localization_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  setUpAll(() async {
    await LocalizationService.instance.ensureLoaded();
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

  test('saved greeting style persists across provider containers', () async {
    final first = ProviderContainer();
    addTearDown(first.dispose);

    await Future<void>.delayed(Duration.zero);
    expect(
      first.read(dashboardGreetingDisplayProvider).primary,
      'Assalamualaikum',
    );

    await first
        .read(dashboardGreetingStyleProvider.notifier)
        .setStyle(DashboardGreetingStyle.assalamualaikumNamaste);

    first.dispose();

    final restarted = ProviderContainer();
    addTearDown(restarted.dispose);
    await Future<void>.delayed(Duration.zero);

    final display = restarted.read(dashboardGreetingDisplayProvider);
    expect(display.primary, 'Assalamualaikum');
    expect(display.secondary, 'Namaste');
  });
}
