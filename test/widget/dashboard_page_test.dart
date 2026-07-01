import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bt_business/features/home/domain/entities/dashboard_summary.dart';
import 'package:bt_business/features/home/presentation/pages/home_dashboard_page.dart';
import 'package:bt_business/features/home/presentation/providers/dashboard_extras_provider.dart';
import 'package:bt_business/features/home/presentation/providers/dashboard_provider.dart';
import 'package:bt_business/features/business/domain/entities/currency.dart';
import 'package:bt_business/features/business/presentation/providers/business_providers.dart';
import 'package:bt_business/features/business/domain/entities/business.dart';
import 'package:bt_business/features/reports/data/datasources/transaction_history_local_datasource.dart';

void main() {
  testWidgets('dashboard shows four summary cards and quick actions', (tester) async {
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
          dashboardRecentActivityProvider.overrideWith(
            (ref) async => [
              TransactionHistoryEntry(
                id: 'tx-1',
                type: 'sale',
                date: DateTime(2026, 6, 30),
                createdAt: DateTime(2026, 6, 30, 10, 30),
                amount: 500,
                label: 'Bikri',
                partyName: 'Suresh',
              ),
            ],
          ),
          dashboardLowStockProvider.overrideWith((ref) async => []),
        ],
        child: const MaterialApp(home: HomeDashboardPage()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Ram Kirana'), findsOneWidget);
    expect(find.text("Today's Sale"), findsOneWidget);
    expect(find.text('Aaj Ki Bikri'), findsOneWidget);
    expect(find.text("Today's Cash"), findsOneWidget);
    expect(find.text('Aaj Cash Mila'), findsOneWidget);
    expect(find.text("Today's Credit"), findsOneWidget);
    expect(find.text('Aaj Udhaar Bana'), findsOneWidget);
    expect(find.text('Cash In Hand'), findsOneWidget);
    expect(find.text('Haath Mein Cash'), findsOneWidget);
    expect(find.text('Sell'), findsOneWidget);
    expect(find.text('Maal Becha'), findsOneWidget);
    expect(find.text('Purchase'), findsOneWidget);
    expect(find.text('Maal Kharida'), findsOneWidget);
    expect(find.text('Cash Received'), findsOneWidget);
    expect(find.text('Paise Mile'), findsOneWidget);
    expect(find.text('Payment'), findsOneWidget);
    expect(find.text('Paise Diya'), findsOneWidget);
    expect(find.text('Expense'), findsOneWidget);
    expect(find.text('Kharcha'), findsOneWidget);
    expect(find.text('Suresh'), findsOneWidget);
    expect(find.text('Developed by Mohd Anas Mansoori'), findsOneWidget);
  });
}

class _StaticDashboardNotifier extends DashboardNotifier {
  @override
  Future<DashboardSummary> build() async {
    return const DashboardSummary(
      todaysProfit: 0,
      todaysSales: 1000,
      todaysCashReceived: 400,
      todaysUdhaarCreated: 600,
      todaysPurchase: 0,
      todaysExpenses: 0,
      cashInHand: 2500,
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
    );
  }
}
