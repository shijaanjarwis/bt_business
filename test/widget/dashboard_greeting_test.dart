import 'package:bt_business/core/localization/greeting_copy.dart';
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

void main() {
  testWidgets('dashboard shows approved greeting not Welcome', (tester) async {
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

    expect(find.text(GreetingCopy.english), findsOneWidget);
    expect(find.text('Welcome'), findsNothing);
    for (final banned in GreetingCopy.forbidden) {
      expect(find.text(banned), findsNothing);
    }
  });
}

class _StaticDashboardNotifier extends DashboardNotifier {
  @override
  Future<DashboardSummary> build() async {
    return DashboardSummary.zero;
  }
}
