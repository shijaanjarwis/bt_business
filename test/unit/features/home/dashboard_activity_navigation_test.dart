import 'package:bt_business/core/accounting/transaction_types.dart';
import 'package:bt_business/core/router/route_names.dart';
import 'package:bt_business/features/home/presentation/utils/dashboard_activity_navigation.dart';
import 'package:bt_business/features/reports/data/datasources/transaction_history_local_datasource.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('payment activity opens edit screen not blank form', (tester) async {
    const paymentId = 'pay-123';
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  DashboardActivityNavigation.open(
                    context,
                    TransactionHistoryEntry(
                      id: paymentId,
                      type: TransactionTypes.paymentReceived,
                      date: DateTime(2026, 6, 30),
                      createdAt: DateTime(2026, 6, 30, 10),
                      amount: 500,
                      label: 'Paise Mile',
                      partyName: 'Ram',
                    ),
                  );
                },
                child: const Text('Open'),
              );
            },
          ),
        ),
        GoRoute(
          path: '/payments/:id/edit',
          builder: (_, state) => Text('edit:${state.pathParameters['id']}'),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('edit:$paymentId'), findsOneWidget);
    expect(find.text(RouteNames.paymentsReceived), findsNothing);
  });
}
