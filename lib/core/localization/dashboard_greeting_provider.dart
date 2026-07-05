import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dashboard_greeting.dart';
import 'language_provider.dart';

const _dashboardGreetingStyleKey = 'dashboard_greeting_style';

/// Persisted dashboard greeting style — survives app restart.
final dashboardGreetingStyleProvider =
    NotifierProvider<DashboardGreetingStyleNotifier, DashboardGreetingStyle>(
  DashboardGreetingStyleNotifier.new,
);

/// Live greeting lines for the dashboard header.
final dashboardGreetingDisplayProvider = Provider<DashboardGreetingDisplay>((ref) {
  final style = ref.watch(dashboardGreetingStyleProvider);
  final language = ref.watch(assistantLanguageProvider);
  return DashboardGreetingCopy.forStyle(style, language: language);
});

final class DashboardGreetingStyleNotifier extends Notifier<DashboardGreetingStyle> {
  @override
  DashboardGreetingStyle build() {
    _restorePersisted();
    return DashboardGreetingStyle.defaultStyle;
  }

  Future<void> _restorePersisted() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = DashboardGreetingStyle.fromCode(
      prefs.getString(_dashboardGreetingStyleKey),
    );
    if (saved != null && saved != state) {
      state = saved;
    } else if (saved == null) {
      await prefs.setString(
        _dashboardGreetingStyleKey,
        DashboardGreetingStyle.defaultStyle.storageCode,
      );
    }
  }

  Future<void> setStyle(DashboardGreetingStyle style) async {
    state = style;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_dashboardGreetingStyleKey, style.storageCode);
  }
}
