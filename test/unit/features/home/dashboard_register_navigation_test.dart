import 'package:bt_business/core/utils/register_date_period.dart';
import 'package:bt_business/features/home/domain/entities/dashboard_summary.dart';
import 'package:bt_business/features/home/presentation/models/dashboard_metric.dart';
import 'package:bt_business/features/home/presentation/models/dashboard_metrics_builder.dart';
import 'package:bt_business/features/home/presentation/utils/dashboard_register_navigation.dart';
import 'package:bt_business/features/payments/presentation/models/payment_register_filter.dart';
import 'package:bt_business/features/payments/presentation/providers/payment_providers.dart';
import 'package:bt_business/features/sales/presentation/models/sale_register_filter.dart';
import 'package:bt_business/features/sales/presentation/providers/sale_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('today sales card sets sale register to today', (tester) async {
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
          path: '/sales',
          builder: (_, _) => const SizedBox(key: Key('sales')),
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

    expect(container.read(saleRegisterDatePeriodProvider), RegisterDatePeriod.today);
    expect(container.read(saleRegisterFilterProvider), SaleRegisterFilter.all);
    expect(find.byKey(const Key('sales')), findsOneWidget);
  });

  testWidgets('today cash card sets payment register to received today', (tester) async {
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
      (m) => m.target == DashboardMetricTarget.todayCash,
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
                child: const Text('Open Payments'),
              );
            },
          ),
        ),
        GoRoute(
          path: '/payments',
          builder: (_, _) => const SizedBox(key: Key('payments')),
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

    await tester.tap(find.text('Open Payments'));
    await tester.pumpAndSettle();

    expect(container.read(paymentRegisterDatePeriodProvider), RegisterDatePeriod.today);
    expect(container.read(paymentRegisterFilterProvider), PaymentRegisterFilter.received);
    expect(find.byKey(const Key('payments')), findsOneWidget);
  });
}
