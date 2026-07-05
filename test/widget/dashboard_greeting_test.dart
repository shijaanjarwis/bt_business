import 'package:bt_business/core/localization/assistant_language.dart';
import 'package:bt_business/core/localization/dashboard_greeting.dart';
import 'package:bt_business/core/localization/language_provider.dart';
import 'package:bt_business/core/reminders/reminder_models.dart';
import 'package:bt_business/core/reminders/reminder_providers.dart';
import 'package:bt_business/features/business/domain/entities/business.dart';
import 'package:bt_business/features/business/domain/entities/currency.dart';
import 'package:bt_business/features/business/presentation/providers/business_providers.dart';
import 'package:bt_business/features/home/domain/entities/dashboard_summary.dart';
import 'package:bt_business/features/home/presentation/pages/home_dashboard_page.dart';
import 'package:bt_business/features/home/presentation/providers/dashboard_extras_provider.dart';
import 'package:bt_business/features/home/presentation/providers/dashboard_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('dashboard shows saved greeting not Welcome', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dashboardProvider.overrideWith(_StaticDashboardNotifier.new),
          businessProfileProvider.overrideWith(
            (ref) async => Business(
              id: 'biz-1',
              name: 'Ram Kirana',
              address: 'Delhi',
              phone: '9876543210',
              email: 'ram@example.com',
              financialYearStartMonth: 4,
              currency: BusinessCurrency.inr,
              createdAt: DateTime(2026, 1, 1),
              updatedAt: DateTime(2026, 1, 1),
            ),
          ),
          dashboardRecentActivityProvider.overrideWith((ref) async => []),
          dashboardLowStockProvider.overrideWith((ref) async => []),
          dashboardDueRemindersProvider.overrideWith((ref) async => []),
          reminderSummaryProvider.overrideWith(
            (ref) async => ReminderDashboardSummary.zero,
          ),
        ],
        child: const MaterialApp(home: HomeDashboardPage()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Assalamualaikum'), findsOneWidget);
    expect(find.text('(Namaste)'), findsOneWidget);
    expect(find.text('Welcome'), findsNothing);
    for (final banned in DashboardGreetingCopy.forbidden) {
      expect(find.text(banned), findsNothing);
    }
  });

  testWidgets('dashboard greeting updates when saved setting changes', (tester) async {
    late ProviderContainer container;

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container = ProviderContainer(
          overrides: [
            dashboardProvider.overrideWith(_StaticDashboardNotifier.new),
            businessProfileProvider.overrideWith(
              (ref) async => Business(
                id: 'biz-1',
                name: 'Ram Kirana',
                address: 'Delhi',
                phone: '9876543210',
                email: 'ram@example.com',
                financialYearStartMonth: 4,
                currency: BusinessCurrency.inr,
                createdAt: DateTime(2026, 1, 1),
                updatedAt: DateTime(2026, 1, 1),
              ),
            ),
            dashboardRecentActivityProvider.overrideWith((ref) async => []),
            dashboardLowStockProvider.overrideWith((ref) async => []),
            dashboardDueRemindersProvider.overrideWith((ref) async => []),
            reminderSummaryProvider.overrideWith(
              (ref) async => ReminderDashboardSummary.zero,
            ),
          ],
        ),
        child: const MaterialApp(home: HomeDashboardPage()),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Assalamualaikum'), findsOneWidget);

    await container
        .read(assistantLanguageProvider.notifier)
        .setAssistantLanguage(AssistantLanguage.hindi);
    await tester.pumpAndSettle();

    expect(find.text('अस्सलामु अलैकुम'), findsOneWidget);
    expect(find.text('(नमस्ते)'), findsOneWidget);
    expect(find.text('Welcome'), findsNothing);

    container.dispose();
  });
}

class _StaticDashboardNotifier extends DashboardNotifier {
  @override
  Future<DashboardSummary> build() async {
    return DashboardSummary.zero;
  }
}
