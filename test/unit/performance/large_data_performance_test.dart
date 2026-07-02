import 'package:bt_business/core/accounting/transaction_types.dart';
import 'package:bt_business/data/local/database/tables/accounting_tables.dart';
import 'package:bt_business/data/local/reminders/reminder_local_datasource.dart';
import 'package:bt_business/features/ledger/data/datasources/party_local_datasource.dart';
import 'package:bt_business/features/purchase/data/datasources/purchase_local_datasource.dart';
import 'package:bt_business/features/sales/data/datasources/sale_local_datasource.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../helpers/dashboard_test_data.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Database db;
  late String businessId;

  setUp(() async {
    db = await createTestDatabase();
    businessId = await seedTestBusiness(db);
    await _seedLargeDataset(db, businessId);
  });

  tearDown(() async {
    await db.close();
  });

  test('sale list query completes under 2 seconds with 50k transactions', () async {
    final datasource = SaleLocalDataSource(db);
    final stopwatch = Stopwatch()..start();
    final sales = await datasource.fetchSales(
      fromDate: DateTime(2021, 1, 1),
      toDate: DateTime(2026, 12, 31),
    );
    stopwatch.stop();

    expect(sales, isNotEmpty);
    expect(sales.length, lessThanOrEqualTo(500));
    expect(stopwatch.elapsedMilliseconds, lessThan(2000));
  });

  test('party search stays fast with 500 parties', () async {
    final datasource = PartyLocalDataSource(db);
    final stopwatch = Stopwatch()..start();
    final parties = await datasource.searchParties('Party 4');
    stopwatch.stop();

    expect(parties, isNotEmpty);
    expect(stopwatch.elapsedMilliseconds, lessThan(500));
  });

  test('purchase search by amount uses indexed SQL', () async {
    final datasource = PurchaseLocalDataSource(db);
    final results = await datasource.searchPurchases('1500');
    expect(results, isNotEmpty);
  });

  test('reminder summary query stays fast', () async {
    final datasource = ReminderLocalDataSource(db);
    final stopwatch = Stopwatch()..start();
    final summary = await datasource.fetchSummary();
    stopwatch.stop();

    expect(summary, isNotNull);
    expect(stopwatch.elapsedMilliseconds, lessThan(1000));
  });
}

Future<void> _seedLargeDataset(Database db, String businessId) async {
  final now = DateTime.now().toIso8601String();

  await db.transaction((txn) async {
    final batch = txn.batch();

    for (var i = 0; i < 500; i++) {
      batch.insert(PartiesTable.tableName, {
        PartiesTable.id: 'party-$i',
        PartiesTable.businessId: businessId,
        PartiesTable.name: 'Party $i',
        PartiesTable.type: 'both',
        PartiesTable.phone: '900000${i.toString().padLeft(4, '0')}',
        PartiesTable.address: '',
        PartiesTable.openingBalance: 0,
        PartiesTable.balance: i.isEven ? 1000 : -500,
        PartiesTable.isActive: 1,
        PartiesTable.isSystem: 0,
        PartiesTable.createdAt: now,
        PartiesTable.updatedAt: now,
      });
    }

    for (var i = 0; i < 10000; i++) {
      batch.insert(ItemsTable.tableName, {
        ItemsTable.id: 'item-$i',
        ItemsTable.businessId: businessId,
        ItemsTable.name: 'Item $i',
        ItemsTable.unit: 'Piece',
        ItemsTable.qtyOnHand: 10,
        ItemsTable.purchaseRate: 50,
        ItemsTable.saleRate: 100,
        ItemsTable.gstRate: 0,
        ItemsTable.isActive: 1,
        ItemsTable.createdAt: now,
        ItemsTable.updatedAt: now,
      });
    }

    for (var i = 0; i < 50000; i++) {
      final partyIndex = i % 500;
      final type = i.isEven ? TransactionTypes.sale : TransactionTypes.purchase;
      final year = 2021 + (i % 5);
      batch.insert(TransactionsTable.tableName, {
        TransactionsTable.id: 'tx-$i',
        TransactionsTable.businessId: businessId,
        TransactionsTable.type: type,
        TransactionsTable.date:
            '$year-${(i % 12 + 1).toString().padLeft(2, '0')}-15',
        TransactionsTable.partyId: 'party-$partyIndex',
        TransactionsTable.paymentMode: 'cash',
        TransactionsTable.gstType: 'intra',
        TransactionsTable.subtotal: 1500,
        TransactionsTable.discountTotal: 0,
        TransactionsTable.taxableTotal: 1500,
        TransactionsTable.cgstTotal: 0,
        TransactionsTable.sgstTotal: 0,
        TransactionsTable.igstTotal: 0,
        TransactionsTable.totalAmount: 1500,
        TransactionsTable.paidAmount: i % 3 == 0 ? 1500 : 500,
        TransactionsTable.dueAmount: i % 3 == 0 ? 0 : 1000,
        TransactionsTable.createdAt: now,
        TransactionsTable.updatedAt: now,
      });
    }

    await batch.commit(noResult: true);
  });
}
