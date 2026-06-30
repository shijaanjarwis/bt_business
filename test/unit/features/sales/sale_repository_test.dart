import 'package:bt_business/core/accounting/gst_types.dart';
import 'package:bt_business/core/accounting/payment_modes.dart';
import 'package:bt_business/data/local/database/tables/accounting_tables.dart';
import 'package:bt_business/features/sales/data/datasources/sale_local_datasource.dart';
import 'package:bt_business/features/sales/data/repositories/sale_repository_impl.dart';
import 'package:bt_business/features/sales/data/services/sale_posting_service.dart';
import 'package:bt_business/features/sales/domain/entities/sale_invoice.dart';
import 'package:bt_business/features/sales/domain/repositories/sale_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../helpers/dashboard_test_data.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late SaleRepository repository;
  late Database db;
  late String businessId;
  late String customerId;
  late String itemId;

  setUp(() async {
    db = await createTestDatabase();
    businessId = await seedTestBusiness(db);
    customerId = await insertCustomer(db: db, businessId: businessId, name: 'Ramesh');
    itemId = await insertStockItem(
      db: db,
      businessId: businessId,
      name: 'Widget',
      qty: 10,
      purchaseRate: 50,
      saleRate: 100,
      gstRate: 18,
    );
    repository = SaleRepositoryImpl(
      SaleLocalDataSource(db),
      SalePostingService(db),
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('saveSale creates cash invoice with stock deduction and journal', () async {
    final result = await repository.saveSale(
      SaveSaleInput(
        date: DateTime(2026, 6, 30),
        partyId: customerId,
        paymentMode: PaymentMode.cash,
        gstType: GstType.intra,
        lines: [
          SaleLineInput(
            itemId: itemId,
            itemName: 'Widget',
            qty: 2,
            rate: 100,
            gstRate: 18,
          ),
        ],
      ),
    );

    expect(result.isSuccess, isTrue, reason: result.failureOrNull?.message);
    final invoice = result.valueOrNull!;
    expect(invoice.invoiceNo.startsWith('SAL-'), isTrue);
    expect(invoice.grandTotal, closeTo(236, 0.01));

    final itemRows = await db.query(ItemsTable.tableName, where: 'id = ?', whereArgs: [itemId]);
    expect(itemRows.first[ItemsTable.qtyOnHand], 8);

    final journalCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM ${JournalLinesTable.tableName}'),
    );
    expect(journalCount, greaterThan(2));
  });

  test('deleteSale restores stock', () async {
    final saved = await repository.saveSale(
      SaveSaleInput(
        date: DateTime(2026, 6, 30),
        partyId: customerId,
        paymentMode: PaymentMode.cash,
        gstType: GstType.intra,
        lines: [
          SaleLineInput(
            itemId: itemId,
            itemName: 'Widget',
            qty: 3,
            rate: 100,
            gstRate: 18,
          ),
        ],
      ),
    );

    await repository.deleteSale(saved.valueOrNull!.id);

    final itemRows = await db.query(ItemsTable.tableName, where: 'id = ?', whereArgs: [itemId]);
    expect(itemRows.first[ItemsTable.qtyOnHand], 10);
  });
}
