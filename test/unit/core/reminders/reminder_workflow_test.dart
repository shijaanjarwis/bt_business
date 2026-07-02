import 'package:bt_business/core/accounting/gst_types.dart';
import 'package:bt_business/core/accounting/payment_modes.dart';
import 'package:bt_business/core/accounting/transaction_types.dart';
import 'package:bt_business/core/reminders/reminder_models.dart';
import 'package:bt_business/core/reminders/reminder_service.dart';
import 'package:bt_business/data/local/database/tables/accounting_tables.dart';
import 'package:bt_business/data/local/reminders/reminder_local_datasource.dart';
import 'package:bt_business/features/ledger/data/services/payment_posting_service.dart';
import 'package:bt_business/features/sales/data/datasources/sale_local_datasource.dart';
import 'package:bt_business/features/sales/data/repositories/sale_repository_impl.dart';
import 'package:bt_business/features/sales/data/services/sale_posting_service.dart';
import 'package:bt_business/features/sales/domain/entities/sale_entry.dart';
import 'package:bt_business/features/sales/domain/repositories/sale_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../helpers/dashboard_test_data.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Database db;
  late String businessId;
  late String customerId;
  late String itemId;
  late SaleRepository saleRepository;
  late PaymentPostingService paymentService;
  late ReminderLocalDataSource reminderDatasource;

  setUp(() async {
    db = await createTestDatabase();
    businessId = await seedTestBusiness(db);
    customerId = await insertCustomer(db: db, businessId: businessId, name: 'Mateen Traders');
    itemId = await insertStockItem(
      db: db,
      businessId: businessId,
      name: 'Steel Rod',
      qty: 100,
      purchaseRate: 50,
      saleRate: 100,
      gstRate: 0,
    );
    saleRepository = SaleRepositoryImpl(
      SaleLocalDataSource(db),
      SalePostingService(db),
    );
    paymentService = PaymentPostingService(db);
    reminderDatasource = ReminderLocalDataSource(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('credit sale stores reminder and edited partial payment keeps it', () async {
    final saved = await saleRepository.saveSale(
      SaveSaleInput(
        date: DateTime(2026, 6, 27),
        partyId: customerId,
        paymentMode: PaymentMode.credit,
        paidAmount: 12000,
        gstType: GstType.intra,
        reminderDate: DateTime(2026, 6, 30),
        lines: [
          SaleLineInput(
            itemId: itemId,
            itemName: 'Steel Rod',
            qty: 3,
            rate: 10000,
            gstRate: 0,
          ),
        ],
      ),
    );
    expect(saved.isSuccess, isTrue);
    final saleId = saved.valueOrNull!.id;

    var reminders = await reminderDatasource.fetchActiveReminders();
    expect(reminders, hasLength(1));
    expect(reminders.first.amount, 18000);

    final updated = await saleRepository.saveSale(
      SaveSaleInput(
        id: saleId,
        date: DateTime(2026, 6, 27),
        partyId: customerId,
        paymentMode: PaymentMode.credit,
        paidAmount: 20000,
        gstType: GstType.intra,
        reminderDate: DateTime(2026, 6, 30),
        lines: [
          SaleLineInput(
            itemId: itemId,
            itemName: 'Steel Rod',
            qty: 3,
            rate: 10000,
            gstRate: 0,
          ),
        ],
      ),
    );
    expect(updated.isSuccess, isTrue);

    reminders = await reminderDatasource.fetchActiveReminders();
    expect(reminders, hasLength(1));
    expect(reminders.first.amount, 10000);
    expect(reminders.first.reminderDate, DateTime(2026, 6, 30));
  });

  test('full payment clears reminder automatically', () async {
    final saved = await saleRepository.saveSale(
      SaveSaleInput(
        date: DateTime(2026, 6, 27),
        partyId: customerId,
        paymentMode: PaymentMode.credit,
        paidAmount: 0,
        gstType: GstType.intra,
        reminderDate: DateTime(2026, 6, 30),
        lines: [
          SaleLineInput(
            itemId: itemId,
            itemName: 'Steel Rod',
            qty: 1,
            rate: 1000,
            gstRate: 0,
          ),
        ],
      ),
    );
    expect(saved.isSuccess, isTrue);

    await saleRepository.saveSale(
      SaveSaleInput(
        id: saved.valueOrNull!.id,
        date: DateTime(2026, 6, 27),
        partyId: customerId,
        paymentMode: PaymentMode.credit,
        paidAmount: 1000,
        gstType: GstType.intra,
        reminderDate: DateTime(2026, 6, 30),
        lines: [
          SaleLineInput(
            itemId: itemId,
            itemName: 'Steel Rod',
            qty: 1,
            rate: 1000,
            gstRate: 0,
          ),
        ],
      ),
    );

    final saleRows = await db.query(TransactionsTable.tableName);
    expect(saleRows.first[TransactionsTable.dueAmount], 0);
    expect(saleRows.first[TransactionsTable.reminderDate], isNull);

    final reminders = await reminderDatasource.fetchActiveReminders();
    expect(reminders, isEmpty);
  });

  test('cash sale does not keep reminder', () async {
    await saleRepository.saveSale(
      SaveSaleInput(
        date: DateTime(2026, 6, 30),
        partyId: customerId,
        paymentMode: PaymentMode.cash,
        paidAmount: 1000,
        gstType: GstType.intra,
        reminderDate: DateTime(2026, 7, 3),
        lines: [
          SaleLineInput(
            itemId: itemId,
            itemName: 'Steel Rod',
            qty: 1,
            rate: 1000,
            gstRate: 0,
          ),
        ],
      ),
    );

    final reminders = await reminderDatasource.fetchActiveReminders();
    expect(reminders, isEmpty);
  });

  test('payment receive can store standalone reminder', () async {
    await paymentService.recordReceived(
      businessId: businessId,
      partyId: customerId,
      amount: 5000,
      date: DateTime(2026, 6, 30),
      reminderDate: DateTime(2026, 7, 2),
    );

    final reminders = await reminderDatasource.fetchActiveReminders();
    expect(reminders, hasLength(1));
    expect(reminders.first.direction, ReminderDirection.receive);
    expect(
      ReminderService.isPending(
        transactionType: TransactionTypes.paymentReceived,
        dueAmount: 0,
        reminderDate: reminders.first.reminderDate,
      ),
      isTrue,
    );
  });

  test('overdue reminders stay in due list until completed', () async {
    await saleRepository.saveSale(
      SaveSaleInput(
        date: DateTime(2026, 6, 20),
        partyId: customerId,
        paymentMode: PaymentMode.credit,
        paidAmount: 0,
        gstType: GstType.intra,
        reminderDate: DateTime(2026, 6, 25),
        lines: [
          SaleLineInput(
            itemId: itemId,
            itemName: 'Steel Rod',
            qty: 1,
            rate: 2000,
            gstRate: 0,
          ),
        ],
      ),
    );

    final due = await reminderDatasource.fetchDueReminders(asOf: DateTime(2026, 6, 30));
    expect(due, hasLength(1));
    expect(due.first.isOverdue, isTrue);
    expect(ReminderService.dueLabel(due.first.reminderDate, reference: DateTime(2026, 6, 30)),
        'Overdue by 5 days');
  });
}
