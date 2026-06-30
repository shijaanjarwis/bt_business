import 'package:bt_business/core/accounting/account_types.dart';
import 'package:bt_business/core/accounting/transaction_types.dart';
import 'package:bt_business/core/utils/date_formatter.dart';
import 'package:bt_business/core/utils/id_generator.dart';
import 'package:bt_business/data/local/database/migrations/migration_runner.dart';
import 'package:bt_business/data/local/database/seeders/account_seeder.dart';
import 'package:bt_business/data/local/database/tables/accounting_tables.dart';
import 'package:bt_business/features/business/data/datasources/business_table.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<Database> createTestDatabase() async {
  return openDatabase(
    inMemoryDatabasePath,
    version: 4,
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
  return businessId;
}

Future<void> insertSale({
  required Database db,
  required String businessId,
  required double amount,
  DateTime? date,
}) async {
  final isoDate = DateFormatter.isoDate(date ?? DateTime.now());
  final now = DateTime.now().toIso8601String();
  final transactionId = IdGenerator.newId();

  await db.insert(TransactionsTable.tableName, {
    TransactionsTable.id: transactionId,
    TransactionsTable.businessId: businessId,
    TransactionsTable.type: TransactionTypes.sale,
    TransactionsTable.date: isoDate,
    TransactionsTable.totalAmount: amount,
    TransactionsTable.createdAt: now,
    TransactionsTable.updatedAt: now,
  });

  final salesAccount = await _accountId(db, businessId, AccountTypes.sales);
  final cashAccount = await _accountId(db, businessId, AccountTypes.cash);

  await db.insert(JournalLinesTable.tableName, {
    JournalLinesTable.id: IdGenerator.newId(),
    JournalLinesTable.transactionId: transactionId,
    JournalLinesTable.accountId: cashAccount,
    JournalLinesTable.debit: amount,
    JournalLinesTable.credit: 0,
  });
  await db.insert(JournalLinesTable.tableName, {
    JournalLinesTable.id: IdGenerator.newId(),
    JournalLinesTable.transactionId: transactionId,
    JournalLinesTable.accountId: salesAccount,
    JournalLinesTable.debit: 0,
    JournalLinesTable.credit: amount,
  });
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

Future<void> insertStockItem({
  required Database db,
  required String businessId,
  required String name,
  required double qty,
  required double purchaseRate,
}) async {
  final now = DateTime.now().toIso8601String();
  await db.insert(ItemsTable.tableName, {
    ItemsTable.id: IdGenerator.newId(),
    ItemsTable.businessId: businessId,
    ItemsTable.name: name,
    ItemsTable.unit: 'pcs',
    ItemsTable.qtyOnHand: qty,
    ItemsTable.purchaseRate: purchaseRate,
    ItemsTable.saleRate: purchaseRate * 1.2,
    ItemsTable.createdAt: now,
    ItemsTable.updatedAt: now,
  });
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
