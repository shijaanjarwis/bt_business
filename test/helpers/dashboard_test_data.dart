import 'package:bt_business/core/accounting/account_types.dart';
import 'package:bt_business/core/accounting/transaction_types.dart';
import 'package:bt_business/core/utils/date_formatter.dart';
import 'package:bt_business/core/utils/id_generator.dart';
import 'package:bt_business/data/local/database/migrations/migration_runner.dart';
import 'package:bt_business/data/local/database/seeders/account_seeder.dart';
import 'package:bt_business/data/local/database/seeders/cash_customer_seeder.dart';
import 'package:bt_business/data/local/database/tables/accounting_tables.dart';
import 'package:bt_business/features/business/data/datasources/business_table.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<Database> createTestDatabase() async {
  return openDatabase(
    inMemoryDatabasePath,
    version: 8,
    singleInstance: false,
    onConfigure: (db) async {
      await db.execute('PRAGMA foreign_keys = ON');
    },
    onCreate: MigrationRunner.onCreate,
    onUpgrade: MigrationRunner.onUpgrade,
  );
}

Future<String> seedTestBusiness(Database db) async {
  const businessId = 'biz-test';
  final now = DateTime.now().toIso8601String();

  await db.insert(BusinessTable.tableName, {
    BusinessTable.id: businessId,
    BusinessTable.name: 'Test Business',
    BusinessTable.address: 'Delhi',
    BusinessTable.phone: '9876543210',
    BusinessTable.email: 'test@example.com',
    BusinessTable.financialYearStartMonth: 4,
    BusinessTable.currencyCode: 'INR',
    BusinessTable.createdAt: now,
    BusinessTable.updatedAt: now,
  });

  await AccountSeeder.seedForBusiness(db, businessId);
  await CashCustomerSeeder.seedForBusiness(db, businessId);
  return businessId;
}

Future<void> insertSale({
  required Database db,
  required String businessId,
  required double amount,
  DateTime? date,
  double paidAmount = 0,
  double dueAmount = 0,
  String? partyId,
}) async {
  final isoDate = DateFormatter.isoDate(date ?? DateTime.now());
  final now = DateTime.now().toIso8601String();
  final transactionId = IdGenerator.newId();
  final paid = paidAmount > 0 ? paidAmount : amount;
  final due = dueAmount > 0 ? dueAmount : (amount - paid).clamp(0, amount);

  await db.insert(TransactionsTable.tableName, {
    TransactionsTable.id: transactionId,
    TransactionsTable.businessId: businessId,
    TransactionsTable.type: TransactionTypes.sale,
    TransactionsTable.date: isoDate,
    TransactionsTable.partyId: partyId,
    TransactionsTable.totalAmount: amount,
    TransactionsTable.paidAmount: paid,
    TransactionsTable.dueAmount: due,
    TransactionsTable.createdAt: now,
    TransactionsTable.updatedAt: now,
  });

  final salesAccount = await _accountId(db, businessId, AccountTypes.sales);
  final cashAccount = await _accountId(db, businessId, AccountTypes.cash);
  final receivableAccount = await _accountId(db, businessId, AccountTypes.receivable);

  if (paid > 0) {
    await db.insert(JournalLinesTable.tableName, {
      JournalLinesTable.id: IdGenerator.newId(),
      JournalLinesTable.transactionId: transactionId,
      JournalLinesTable.accountId: cashAccount,
      JournalLinesTable.debit: paid,
      JournalLinesTable.credit: 0,
    });
  }
  if (due > 0) {
    await db.insert(JournalLinesTable.tableName, {
      JournalLinesTable.id: IdGenerator.newId(),
      JournalLinesTable.transactionId: transactionId,
      JournalLinesTable.accountId: receivableAccount,
      JournalLinesTable.partyId: partyId,
      JournalLinesTable.debit: due,
      JournalLinesTable.credit: 0,
    });
  }
  await db.insert(JournalLinesTable.tableName, {
    JournalLinesTable.id: IdGenerator.newId(),
    JournalLinesTable.transactionId: transactionId,
    JournalLinesTable.accountId: salesAccount,
    JournalLinesTable.debit: 0,
    JournalLinesTable.credit: amount,
  });
}

Future<void> insertCashJournal({
  required Database db,
  required String businessId,
  required String transactionType,
  required double cashIn,
  required double cashOut,
  DateTime? date,
}) async {
  final isoDate = DateFormatter.isoDate(date ?? DateTime.now());
  final now = DateTime.now().toIso8601String();
  final transactionId = IdGenerator.newId();
  final cashAccount = await _accountId(db, businessId, AccountTypes.cash);
  final offsetAccount = await _accountId(db, businessId, AccountTypes.expense);

  await db.insert(TransactionsTable.tableName, {
    TransactionsTable.id: transactionId,
    TransactionsTable.businessId: businessId,
    TransactionsTable.type: transactionType,
    TransactionsTable.date: isoDate,
    TransactionsTable.totalAmount: cashIn > 0 ? cashIn : cashOut,
    TransactionsTable.createdAt: now,
    TransactionsTable.updatedAt: now,
  });

  if (cashIn > 0) {
    await db.insert(JournalLinesTable.tableName, {
      JournalLinesTable.id: IdGenerator.newId(),
      JournalLinesTable.transactionId: transactionId,
      JournalLinesTable.accountId: cashAccount,
      JournalLinesTable.debit: cashIn,
      JournalLinesTable.credit: 0,
    });
    await db.insert(JournalLinesTable.tableName, {
      JournalLinesTable.id: IdGenerator.newId(),
      JournalLinesTable.transactionId: transactionId,
      JournalLinesTable.accountId: offsetAccount,
      JournalLinesTable.debit: 0,
      JournalLinesTable.credit: cashIn,
    });
  }
  if (cashOut > 0) {
    await db.insert(JournalLinesTable.tableName, {
      JournalLinesTable.id: IdGenerator.newId(),
      JournalLinesTable.transactionId: transactionId,
      JournalLinesTable.accountId: offsetAccount,
      JournalLinesTable.debit: cashOut,
      JournalLinesTable.credit: 0,
    });
    await db.insert(JournalLinesTable.tableName, {
      JournalLinesTable.id: IdGenerator.newId(),
      JournalLinesTable.transactionId: transactionId,
      JournalLinesTable.accountId: cashAccount,
      JournalLinesTable.debit: 0,
      JournalLinesTable.credit: cashOut,
    });
  }
}

Future<void> softDeleteTransaction({
  required Database db,
  required String transactionId,
}) async {
  final now = DateTime.now().toIso8601String();
  await db.update(
    TransactionsTable.tableName,
    {TransactionsTable.deletedAt: now},
    where: '${TransactionsTable.id} = ?',
    whereArgs: [transactionId],
  );
  await db.update(
    JournalLinesTable.tableName,
    {JournalLinesTable.deletedAt: now},
    where: '${JournalLinesTable.transactionId} = ?',
    whereArgs: [transactionId],
  );
}

Future<void> insertPartyBalance({
  required Database db,
  required String businessId,
  required String name,
  required double balance,
}) async {
  final now = DateTime.now().toIso8601String();
  await db.insert(PartiesTable.tableName, {
    PartiesTable.id: IdGenerator.newId(),
    PartiesTable.businessId: businessId,
    PartiesTable.name: name,
    PartiesTable.type: balance >= 0 ? 'customer' : 'supplier',
    PartiesTable.phone: '',
    PartiesTable.address: '',
    PartiesTable.openingBalance: balance,
    PartiesTable.isActive: 1,
    PartiesTable.balance: balance,
    PartiesTable.createdAt: now,
    PartiesTable.updatedAt: now,
  });
}

Future<String> insertStockItem({
  required Database db,
  required String businessId,
  required String name,
  required double qty,
  required double purchaseRate,
  double saleRate = 0,
  double gstRate = 18,
  String? hsnSac,
}) async {
  final now = DateTime.now().toIso8601String();
  return db.insert(ItemsTable.tableName, {
    ItemsTable.id: IdGenerator.newId(),
    ItemsTable.businessId: businessId,
    ItemsTable.name: name,
    ItemsTable.unit: 'pcs',
    ItemsTable.qtyOnHand: qty,
    ItemsTable.purchaseRate: purchaseRate,
    ItemsTable.saleRate: saleRate > 0 ? saleRate : purchaseRate * 1.2,
    ItemsTable.gstRate: gstRate,
    ItemsTable.hsnSac: hsnSac,
    ItemsTable.isActive: 1,
    ItemsTable.createdAt: now,
    ItemsTable.updatedAt: now,
  }).then((_) async {
    final rows = await db.query(
      ItemsTable.tableName,
      where: '${ItemsTable.name} = ?',
      whereArgs: [name],
      limit: 1,
    );
    return rows.first[ItemsTable.id]! as String;
  });
}

Future<String> insertCustomer({
  required Database db,
  required String businessId,
  required String name,
  String phone = '9876543210',
}) async {
  final id = IdGenerator.newId();
  final now = DateTime.now().toIso8601String();
  await db.insert(PartiesTable.tableName, {
    PartiesTable.id: id,
    PartiesTable.businessId: businessId,
    PartiesTable.name: name,
    PartiesTable.type: 'customer',
    PartiesTable.phone: phone,
    PartiesTable.address: '',
    PartiesTable.openingBalance: 0,
    PartiesTable.isActive: 1,
    PartiesTable.balance: 0,
    PartiesTable.createdAt: now,
    PartiesTable.updatedAt: now,
  });
  return id;
}

Future<String> insertSupplier({
  required Database db,
  required String businessId,
  required String name,
  String phone = '9123456780',
}) async {
  final id = IdGenerator.newId();
  final now = DateTime.now().toIso8601String();
  await db.insert(PartiesTable.tableName, {
    PartiesTable.id: id,
    PartiesTable.businessId: businessId,
    PartiesTable.name: name,
    PartiesTable.type: 'supplier',
    PartiesTable.phone: phone,
    PartiesTable.address: '',
    PartiesTable.openingBalance: 0,
    PartiesTable.isActive: 1,
    PartiesTable.balance: 0,
    PartiesTable.createdAt: now,
    PartiesTable.updatedAt: now,
  });
  return id;
}

Future<String> _accountId(
  Database db,
  String businessId,
  String type,
) async {
  final rows = await db.query(
    AccountsTable.tableName,
    columns: [AccountsTable.id],
    where: '${AccountsTable.businessId} = ? AND ${AccountsTable.type} = ?',
    whereArgs: [businessId, type],
    limit: 1,
  );
  return rows.first[AccountsTable.id]! as String;
}
