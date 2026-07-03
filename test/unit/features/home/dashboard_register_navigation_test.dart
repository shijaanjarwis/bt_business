import 'package:bt_business/core/utils/register_date_period.dart';
import 'package:bt_business/features/home/domain/entities/dashboard_summary.dart';
import 'package:bt_business/features/home/presentation/models/dashboard_metric.dart';
import 'package:bt_business/features/home/presentation/models/dashboard_metrics_builder.dart';
import 'package:bt_business/features/home/presentation/models/dashboard_summary_kind.dart';
import 'package:bt_business/features/home/presentation/providers/dashboard_summary_providers.dart';
import 'package:bt_business/features/home/presentation/utils/dashboard_register_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('today sales card opens dashboard summary detail', (tester) async {
    final metrics = DashboardMetricsBuilder.fromSummary(
      const DashboardSummary(
        todaysProfit: 0,
        todaysSales: 100,
        todaysCashReceived: 0,
        todaysUdhaarCreated: 0,
        todaysPurchase: 0,
        todaysExpenses: 0,
        cashInHand: 0,
        amountInBank: 0,
        todaysReceivables: 0,
        todaysPayables: 0,
        paymentReceived: 0,
        paymentPaid: 0,
        goodsSold: 0,
        goodsPurchased: 0,
        stockValue: 0,
        receivableCount: 0,
        payableCount: 0,
      ),
    );
    final todaySales = metrics.firstWhere(
      (m) => m.target == DashboardMetricTarget.todaySales,
    );

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => Consumer(
            builder: (context, ref, _) {
              return ElevatedButton(
                onPressed: () =>
                    DashboardRegisterNavigation.open(context, ref, todaySales),
                child: const Text('Open Sales'),
              );
            },
          ),
        ),
        GoRoute(
          path: '/summary/:kind',
          builder: (_, state) => SizedBox(
            key: Key('summary-${state.pathParameters['kind']}'),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    final container = ProviderScope.containerOf(
      tester.element(find.byType(MaterialApp)),
    );

    await tester.tap(find.text('Open Sales'));
    await tester.pumpAndSettle();

    expect(
      container.read(dashboardSummaryDatePeriodProvider(DashboardSummaryKind.todaySales)),
      RegisterDatePeriod.today,
    );
    expect(find.byKey(const Key('summary-today-sales')), findsOneWidget);
  });

  testWidgets('today cash received card opens dashboard summary detail', (tester) async {
    final metrics = DashboardMetricsBuilder.fromSummary(
      const DashboardSummary(
        todaysProfit: 0,
        todaysSales: 0,
        todaysCashReceived: 50,
        todaysUdhaarCreated: 0,
        todaysPurchase: 0,
        todaysExpenses: 0,
        cashInHand: 0,
        amountInBank: 0,
        todaysReceivables: 0,
        todaysPayables: 0,
        paymentReceived: 0,
        paymentPaid: 0,
        goodsSold: 0,
        goodsPurchased: 0,
        stockValue: 0,
        receivableCount: 0,
        payableCount: 0,
      ),
    );
    final todayCash = metrics.firstWhere(
      (m) => m.target == DashboardMetricTarget.todayCashReceived,
    );

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => Consumer(
            builder: (context, ref, _) {
              return ElevatedButton(
                onPressed: () =>
                    DashboardRegisterNavigation.open(context, ref, todayCash),
                child: const Text('Open Cash'),
              );
            },
          ),
        ),
        GoRoute(
          path: '/summary/:kind',
          builder: (_, state) => SizedBox(
            key: Key('summary-${state.pathParameters['kind']}'),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    final container = ProviderScope.containerOf(
      tester.element(find.byType(MaterialApp)),
    );

    await tester.tap(find.text('Open Cash'));
    await tester.pumpAndSettle();

    expect(
      container.read(
        dashboardSummaryDatePeriodProvider(DashboardSummaryKind.todayCashReceived),
      ),
      RegisterDatePeriod.today,
    );
    expect(find.byKey(const Key('summary-today-cash-received')), findsOneWidget);
  });
}
