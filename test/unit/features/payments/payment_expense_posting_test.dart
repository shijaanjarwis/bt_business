import 'package:bt_business/core/accounting/account_types.dart';
import 'package:bt_business/core/accounting/transaction_types.dart';
import 'package:bt_business/features/payments/data/services/expense_posting_service.dart';
import 'package:bt_business/features/ledger/data/services/payment_posting_service.dart';
import 'package:bt_business/data/local/database/tables/accounting_tables.dart';
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
  late String partyId;
  late PaymentPostingService paymentService;
  late ExpensePostingService expenseService;

  setUp(() async {
    db = await createTestDatabase();
    businessId = await seedTestBusiness(db);
    partyId = await _insertParty(db, businessId);
    paymentService = PaymentPostingService(db);
    expenseService = ExpensePostingService(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('recordReceived updates party balance and cash', () async {
    await paymentService.recordReceived(
      businessId: businessId,
      partyId: partyId,
      amount: 500,
      date: DateTime.now(),
      note: 'Partial payment',
    );

    final party = await db.query(
      PartiesTable.tableName,
      where: '${PartiesTable.id} = ?',
      whereArgs: [partyId],
    );
    expect(party.first[PartiesTable.balance], 500);

    final cash = await _cashBalance(db, businessId);
    expect(cash, 500);
  });

  test('recordPaid reduces payable balance and cash', () async {
    await db.update(
      PartiesTable.tableName,
      {PartiesTable.balance: -1000},
      where: '${PartiesTable.id} = ?',
      whereArgs: [partyId],
    );

    await paymentService.recordPaid(
      businessId: businessId,
      partyId: partyId,
      amount: 400,
      date: DateTime.now(),
    );

    final party = await db.query(
      PartiesTable.tableName,
      where: '${PartiesTable.id} = ?',
      whereArgs: [partyId],
    );
    expect(party.first[PartiesTable.balance], -600);

    final cash = await _cashBalance(db, businessId);
    expect(cash, -400);
  });

  test('record expense reduces cash', () async {
    await expenseService.record(
      businessId: businessId,
      name: 'Diesel',
      amount: 300,
      date: DateTime.now(),
      note: 'Generator',
    );

    final rows = await db.query(
      TransactionsTable.tableName,
      where: '${TransactionsTable.type} = ?',
      whereArgs: [TransactionTypes.expense],
    );
    expect(rows, hasLength(1));
    expect(rows.first[TransactionsTable.notes], 'Diesel — Generator');
    expect(rows.first[TransactionsTable.totalAmount], 300);

    final cash = await _cashBalance(db, businessId);
    expect(cash, -300);
  });
}

Future<String> _insertParty(Database db, String businessId) async {
  const id = 'party-test-1';
  await db.insert(PartiesTable.tableName, {
    PartiesTable.id: id,
    PartiesTable.businessId: businessId,
    PartiesTable.name: 'Test Party',
    PartiesTable.type: 'customer',
    PartiesTable.phone: '9876543210',
    PartiesTable.balance: 1000,
    PartiesTable.openingBalance: 1000,
    PartiesTable.isActive: 1,
    PartiesTable.createdAt: DateTime.now().toIso8601String(),
    PartiesTable.updatedAt: DateTime.now().toIso8601String(),
  });
  return id;
}

Future<double> _cashBalance(Database db, String businessId) async {
  final rows = await db.rawQuery(
    '''
    SELECT COALESCE(SUM(jl.${JournalLinesTable.debit} - jl.${JournalLinesTable.credit}), 0) AS balance
    FROM ${JournalLinesTable.tableName} jl
    INNER JOIN ${AccountsTable.tableName} a ON jl.${JournalLinesTable.accountId} = a.${AccountsTable.id}
    WHERE a.${AccountsTable.businessId} = ? AND a.${AccountsTable.type} = ?
    ''',
    [businessId, AccountTypes.cash],
  );
  return (rows.first['balance'] as num).toDouble();
}
