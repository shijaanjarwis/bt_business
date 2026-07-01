import 'package:bt_business/core/accounting/transaction_types.dart';
import 'package:bt_business/core/utils/date_formatter.dart';
import 'package:bt_business/core/utils/id_generator.dart';
import 'package:bt_business/data/local/database/tables/accounting_tables.dart';
import 'package:bt_business/features/home/data/services/dashboard_calculation_service.dart';
import 'package:bt_business/features/ledger/data/services/payment_posting_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../helpers/dashboard_test_data.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Database db;
  late DashboardCalculationService service;
  late String businessId;
  late String customerId;
  final today = DateTime(2026, 6, 30);
  late String todayIso;

  setUp(() async {
    db = await createTestDatabase();
    service = const DashboardCalculationService();
    businessId = await seedTestBusiness(db);
    customerId = await insertCustomer(db: db, businessId: businessId, name: 'Ramesh');
    todayIso = DateFormatter.isoDate(today);
  });

  tearDown(() async {
    await db.close();
  });

  group('calculateAajKiBikri', () {
    test('sums total_amount for active sales on the given day', () async {
      await insertSale(db: db, businessId: businessId, amount: 1000, date: today);
      await insertSale(db: db, businessId: businessId, amount: 2500, date: today);

      final result = await service.calculateAajKiBikri(
        db: db,
        businessId: businessId,
        date: todayIso,
      );

      expect(result, 3500);
    });

    test('ignores sales on other days and soft-deleted sales', () async {
      await insertSale(db: db, businessId: businessId, amount: 1000, date: today);
      await insertSale(
        db: db,
        businessId: businessId,
        amount: 9000,
        date: today.subtract(const Duration(days: 1)),
      );

      final deletedId = IdGenerator.newId();
      final now = DateTime.now().toIso8601String();
      await db.insert(
        TransactionsTable.tableName,
        {
          TransactionsTable.id: deletedId,
          TransactionsTable.businessId: businessId,
          TransactionsTable.type: TransactionTypes.sale,
          TransactionsTable.date: todayIso,
          TransactionsTable.totalAmount: 5000,
          TransactionsTable.deletedAt: now,
          TransactionsTable.createdAt: now,
          TransactionsTable.updatedAt: now,
        },
      );

      final result = await service.calculateAajKiBikri(
        db: db,
        businessId: businessId,
        date: todayIso,
      );

      expect(result, 1000);
    });
  });

  group('calculateAajCashMila', () {
    test('sums every cash debit on today transactions', () async {
      await insertSale(
        db: db,
        businessId: businessId,
        amount: 1000,
        paidAmount: 400,
        dueAmount: 600,
        date: today,
        partyId: customerId,
      );

      await PaymentPostingService(db).recordReceived(
        businessId: businessId,
        partyId: customerId,
        amount: 300,
        date: today,
      );

      final result = await service.calculateAajCashMila(
        db: db,
        businessId: businessId,
        date: todayIso,
      );

      expect(result, 700);
    });

    test('excludes cash paid out and soft-deleted cash debits', () async {
      await insertSale(db: db, businessId: businessId, amount: 500, date: today);
      await insertCashJournal(
        db: db,
        businessId: businessId,
        transactionType: TransactionTypes.expense,
        cashIn: 0,
        cashOut: 200,
        date: today,
      );

      final deletedSale = await _insertTrackedSale(db, businessId, 800, today);
      await softDeleteTransaction(db: db, transactionId: deletedSale);

      final result = await service.calculateAajCashMila(
        db: db,
        businessId: businessId,
        date: todayIso,
      );

      expect(result, 500);
    });
  });

  group('calculateAajUdhaarBana', () {
    test('sums due_amount on today sales only', () async {
      await insertSale(
        db: db,
        businessId: businessId,
        amount: 1000,
        paidAmount: 200,
        dueAmount: 800,
        date: today,
        partyId: customerId,
      );
      await insertSale(
        db: db,
        businessId: businessId,
        amount: 500,
        paidAmount: 500,
        dueAmount: 0,
        date: today,
      );

      final result = await service.calculateAajUdhaarBana(
        db: db,
        businessId: businessId,
        date: todayIso,
      );

      expect(result, 800);
    });
  });

  group('calculateCashInHand', () {
    test('returns net cash debits minus credits across all time', () async {
      await insertSale(db: db, businessId: businessId, amount: 1000, date: today);
      await insertCashJournal(
        db: db,
        businessId: businessId,
        transactionType: TransactionTypes.expense,
        cashIn: 0,
        cashOut: 300,
        date: today,
      );
      await PaymentPostingService(db).recordReceived(
        businessId: businessId,
        partyId: customerId,
        amount: 200,
        date: today.subtract(const Duration(days: 2)),
      );

      final result = await service.calculateCashInHand(
        db: db,
        businessId: businessId,
      );

      expect(result, 900);
    });

    test('adds optional opening cash without storing it', () async {
      await insertSale(db: db, businessId: businessId, amount: 500, date: today);

      final result = await service.calculateCashInHand(
        db: db,
        businessId: businessId,
        openingCash: 1000,
      );

      expect(result, 1500);
    });
  });

  group('calculateCoreMetrics', () {
    test('returns all four metrics in one call', () async {
      await insertSale(
        db: db,
        businessId: businessId,
        amount: 1200,
        paidAmount: 500,
        dueAmount: 700,
        date: today,
        partyId: customerId,
      );

      final metrics = await service.calculateCoreMetrics(
        db: db,
        businessId: businessId,
        asOf: today,
      );

      expect(metrics.aajKiBikri, 1200);
      expect(metrics.aajCashMila, 500);
      expect(metrics.aajUdhaarBana, 700);
      expect(metrics.cashInHand, 500);
    });
  });
}

Future<String> _insertTrackedSale(
  Database db,
  String businessId,
  double amount,
  DateTime date,
) async {
  final isoDate = DateFormatter.isoDate(date);
  final now = DateTime.now().toIso8601String();
  final id = IdGenerator.newId();
  await db.insert(
    TransactionsTable.tableName,
    {
      TransactionsTable.id: id,
      TransactionsTable.businessId: businessId,
      TransactionsTable.type: TransactionTypes.sale,
      TransactionsTable.date: isoDate,
      TransactionsTable.totalAmount: amount,
      TransactionsTable.paidAmount: amount,
      TransactionsTable.dueAmount: 0,
      TransactionsTable.createdAt: now,
      TransactionsTable.updatedAt: now,
    },
  );
  return id;
}
