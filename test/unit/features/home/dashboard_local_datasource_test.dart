import 'package:bt_business/features/home/data/datasources/dashboard_local_datasource.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../helpers/dashboard_test_data.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Database db;
  late DashboardLocalDataSource dataSource;

  setUp(() async {
    db = await createTestDatabase();
    dataSource = DashboardLocalDataSource(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('returns zero summary when no business exists', () async {
    final summary = await dataSource.fetchSummary();
    expect(summary.todaysSales, 0);
    expect(summary.todaysCashReceived, 0);
    expect(summary.todaysUdhaarCreated, 0);
    expect(summary.cashInHand, 0);
    expect(summary.stockValue, 0);
  });

  test('aggregates sales, cash, receivables and stock from sqlite', () async {
    final businessId = await seedTestBusiness(db);

    await insertSale(db: db, businessId: businessId, amount: 5000);
    await insertPartyBalance(
      db: db,
      businessId: businessId,
      name: 'Ram Traders',
      balance: 1200,
    );
    await insertPartyBalance(
      db: db,
      businessId: businessId,
      name: 'Shyam Supply',
      balance: -800,
    );
    await insertStockItem(
      db: db,
      businessId: businessId,
      name: 'Rice 25kg',
      qty: 10,
      purchaseRate: 100,
    );

    final summary = await dataSource.fetchSummary();

    expect(summary.todaysSales, 5000);
    expect(summary.todaysCashReceived, 5000);
    expect(summary.todaysUdhaarCreated, 0);
    expect(summary.todaysProfit, 5000);
    expect(summary.cashInHand, 5000);
    expect(summary.todaysReceivables, 1200);
    expect(summary.receivableCount, 1);
    expect(summary.todaysPayables, 800);
    expect(summary.payableCount, 1);
    expect(summary.stockValue, 1000);
  });
}
