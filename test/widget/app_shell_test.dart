import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bt_business/app.dart';
import 'package:bt_business/features/business/presentation/providers/business_providers.dart';
import 'package:bt_business/features/home/domain/entities/dashboard_summary.dart';
import 'package:bt_business/features/home/presentation/providers/dashboard_provider.dart';

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
          ],
          child: const BtBusinessApp(),
        ),
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('BT Business'), findsOneWidget);
    expect(find.text('Jama'), findsOneWidget);
    expect(find.text('Kharch'), findsOneWidget);
    expect(find.text('Cash in Hand'), findsOneWidget);
    expect(find.text('Voice'), findsOneWidget);
    expect(find.text('Dashboard'), findsOneWidget);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
    await tester.pumpAndSettle();

    expect(find.text('Lena Hai'), findsOneWidget);
    expect(find.text('Dena Hai'), findsOneWidget);
    expect(find.text('Aaj ki Bikri'), findsOneWidget);
    expect(find.text('Aaj ka Kharch'), findsOneWidget);
  });
}

class _StaticDashboardNotifier extends DashboardNotifier {
  @override
  Future<DashboardSummary> build() async => DashboardSummary.zero;
}
