import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bt_business/app.dart';
import 'package:bt_business/features/business/presentation/providers/business_providers.dart';
import 'package:bt_business/features/home/domain/entities/dashboard_summary.dart';
import 'package:bt_business/features/home/presentation/providers/dashboard_extras_provider.dart';
import 'package:bt_business/features/home/presentation/providers/dashboard_provider.dart';
import 'package:bt_business/shared/widgets/branding/app_branding.dart';

void main() {
  testWidgets('Home dashboard renders with branding and bilingual labels',
      (tester) async {
    await tester.pumpWidget(
      TickerMode(
        enabled: false,
        child: ProviderScope(
          overrides: [
            businessGateProvider.overrideWith((ref) async => true),
            dashboardProvider.overrideWith(_StaticDashboardNotifier.new),
            dashboardRecentActivityProvider.overrideWith((ref) async => []),
            dashboardLowStockProvider.overrideWith((ref) async => []),
          ],
          child: const BtBusinessApp(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(AppBranding.splashDuration);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.text("Today's Sale"), findsOneWidget);
    expect(find.text('Aaj Ki Bikri'), findsOneWidget);
    expect(find.text("Today's Cash"), findsOneWidget);
    expect(find.text('Aaj Cash Mila'), findsOneWidget);
    expect(find.text('Cash In Hand'), findsOneWidget);
    expect(find.text('Maal Becha'), findsOneWidget);
    expect(find.text('Kharcha'), findsOneWidget);
    expect(find.text('Voice'), findsOneWidget);
    expect(find.text('Dashboard'), findsOneWidget);
  });
}

class _StaticDashboardNotifier extends DashboardNotifier {
  @override
  Future<DashboardSummary> build() async => DashboardSummary.zero;
}
