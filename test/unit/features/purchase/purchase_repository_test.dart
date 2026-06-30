import 'package:bt_business/core/accounting/gst_types.dart';
import 'package:bt_business/core/accounting/payment_modes.dart';
import 'package:bt_business/data/local/database/tables/accounting_tables.dart';
import 'package:bt_business/features/purchase/data/datasources/purchase_local_datasource.dart';
import 'package:bt_business/features/purchase/data/repositories/purchase_repository_impl.dart';
import 'package:bt_business/features/purchase/data/services/purchase_posting_service.dart';
import 'package:bt_business/features/purchase/domain/entities/purchase_invoice.dart';
import 'package:bt_business/features/purchase/domain/repositories/purchase_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../helpers/dashboard_test_data.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late PurchaseRepository repository;
  late Database db;
  late String supplierId;
  late String itemId;

  setUp(() async {
    db = await createTestDatabase();
    final businessId = await seedTestBusiness(db);
    supplierId = await insertSupplier(db: db, businessId: businessId, name: 'ABC Traders');
    itemId = await insertStockItem(
      db: db,
      businessId: businessId,
      name: 'Bolt',
      qty: 5,
      purchaseRate: 40,
      saleRate: 60,
      gstRate: 18,
    );
    repository = PurchaseRepositoryImpl(
      PurchaseLocalDataSource(db),
      PurchasePostingService(db),
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('savePurchase creates cash invoice with stock increase', () async {
    final result = await repository.savePurchase(
      SavePurchaseInput(
        date: DateTime(2026, 6, 30),
        partyId: supplierId,
        paymentMode: PaymentMode.cash,
        gstType: GstType.intra,
        lines: [
          PurchaseLineInput(
            itemId: itemId,
            itemName: 'Bolt',
            qty: 10,
            rate: 50,
            gstRate: 18,
          ),
        ],
      ),
    );

    expect(result.isSuccess, isTrue, reason: result.failureOrNull?.message);
    final invoice = result.valueOrNull!;
    expect(invoice.invoiceNo.startsWith('PUR-'), isTrue);
    expect(invoice.grandTotal, closeTo(590, 0.01));

    final itemRows = await db.query(ItemsTable.tableName, where: 'id = ?', whereArgs: [itemId]);
    expect(itemRows.first[ItemsTable.qtyOnHand], 15);
    expect(itemRows.first[ItemsTable.purchaseRate], 50);
  });

  test('deletePurchase reverses stock increase', () async {
    final saved = await repository.savePurchase(
      SavePurchaseInput(
        date: DateTime(2026, 6, 30),
        partyId: supplierId,
        paymentMode: PaymentMode.cash,
        gstType: GstType.intra,
        lines: [
          PurchaseLineInput(
            itemId: itemId,
            itemName: 'Bolt',
            qty: 4,
            rate: 50,
            gstRate: 18,
          ),
        ],
      ),
    );

    await repository.deletePurchase(saved.valueOrNull!.id);

    final itemRows = await db.query(ItemsTable.tableName, where: 'id = ?', whereArgs: [itemId]);
    expect(itemRows.first[ItemsTable.qtyOnHand], 5);
  });
}
