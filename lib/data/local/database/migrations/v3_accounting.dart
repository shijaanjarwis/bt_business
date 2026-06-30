import 'package:sqflite/sqflite.dart';

import '../../../../features/business/data/datasources/business_table.dart';
import '../seeders/account_seeder.dart';
import '../tables/accounting_tables.dart';
import 'migration.dart';

/// Adds core accounting tables used by the dashboard and future ledger modules.
final class V3AccountingMigration implements Migration {
  @override
  int get version => 3;

  @override
  Future<void> up(Database db) async {
    await db.execute('''
      CREATE TABLE ${AccountsTable.tableName} (
        ${AccountsTable.id} TEXT PRIMARY KEY NOT NULL,
        ${AccountsTable.businessId} TEXT NOT NULL,
        ${AccountsTable.name} TEXT NOT NULL,
        ${AccountsTable.type} TEXT NOT NULL,
        ${AccountsTable.isSystem} INTEGER NOT NULL DEFAULT 1,
        ${AccountsTable.createdAt} TEXT NOT NULL,
        FOREIGN KEY (${AccountsTable.businessId})
          REFERENCES ${BusinessTable.tableName}(${BusinessTable.id})
      )
    ''');

    await db.execute('''
      CREATE TABLE ${PartiesTable.tableName} (
        ${PartiesTable.id} TEXT PRIMARY KEY NOT NULL,
        ${PartiesTable.businessId} TEXT NOT NULL,
        ${PartiesTable.name} TEXT NOT NULL,
        ${PartiesTable.type} TEXT NOT NULL,
        ${PartiesTable.phone} TEXT NOT NULL DEFAULT '',
        ${PartiesTable.balance} REAL NOT NULL DEFAULT 0,
        ${PartiesTable.createdAt} TEXT NOT NULL,
        ${PartiesTable.updatedAt} TEXT NOT NULL,
        FOREIGN KEY (${PartiesTable.businessId})
          REFERENCES ${BusinessTable.tableName}(${BusinessTable.id})
      )
    ''');

    await db.execute('''
      CREATE TABLE ${TransactionsTable.tableName} (
        ${TransactionsTable.id} TEXT PRIMARY KEY NOT NULL,
        ${TransactionsTable.businessId} TEXT NOT NULL,
        ${TransactionsTable.type} TEXT NOT NULL,
        ${TransactionsTable.date} TEXT NOT NULL,
        ${TransactionsTable.partyId} TEXT,
        ${TransactionsTable.invoiceNo} TEXT,
        ${TransactionsTable.notes} TEXT,
        ${TransactionsTable.totalAmount} REAL NOT NULL DEFAULT 0,
        ${TransactionsTable.createdAt} TEXT NOT NULL,
        ${TransactionsTable.updatedAt} TEXT NOT NULL,
        FOREIGN KEY (${TransactionsTable.businessId})
          REFERENCES ${BusinessTable.tableName}(${BusinessTable.id}),
        FOREIGN KEY (${TransactionsTable.partyId})
          REFERENCES ${PartiesTable.tableName}(${PartiesTable.id})
      )
    ''');

    await db.execute('''
      CREATE TABLE ${JournalLinesTable.tableName} (
        ${JournalLinesTable.id} TEXT PRIMARY KEY NOT NULL,
        ${JournalLinesTable.transactionId} TEXT NOT NULL,
        ${JournalLinesTable.accountId} TEXT NOT NULL,
        ${JournalLinesTable.debit} REAL NOT NULL DEFAULT 0,
        ${JournalLinesTable.credit} REAL NOT NULL DEFAULT 0,
        ${JournalLinesTable.partyId} TEXT,
        FOREIGN KEY (${JournalLinesTable.transactionId})
          REFERENCES ${TransactionsTable.tableName}(${TransactionsTable.id}),
        FOREIGN KEY (${JournalLinesTable.accountId})
          REFERENCES ${AccountsTable.tableName}(${AccountsTable.id})
      )
    ''');

    await db.execute('''
      CREATE TABLE ${ItemsTable.tableName} (
        ${ItemsTable.id} TEXT PRIMARY KEY NOT NULL,
        ${ItemsTable.businessId} TEXT NOT NULL,
        ${ItemsTable.name} TEXT NOT NULL,
        ${ItemsTable.unit} TEXT NOT NULL DEFAULT 'pcs',
        ${ItemsTable.qtyOnHand} REAL NOT NULL DEFAULT 0,
        ${ItemsTable.purchaseRate} REAL NOT NULL DEFAULT 0,
        ${ItemsTable.saleRate} REAL NOT NULL DEFAULT 0,
        ${ItemsTable.createdAt} TEXT NOT NULL,
        ${ItemsTable.updatedAt} TEXT NOT NULL,
        FOREIGN KEY (${ItemsTable.businessId})
          REFERENCES ${BusinessTable.tableName}(${BusinessTable.id})
      )
    ''');

    await db.execute('''
      CREATE TABLE ${StockMovementsTable.tableName} (
        ${StockMovementsTable.id} TEXT PRIMARY KEY NOT NULL,
        ${StockMovementsTable.itemId} TEXT NOT NULL,
        ${StockMovementsTable.transactionId} TEXT,
        ${StockMovementsTable.qtyDelta} REAL NOT NULL,
        ${StockMovementsTable.rate} REAL NOT NULL DEFAULT 0,
        ${StockMovementsTable.movementDate} TEXT NOT NULL,
        FOREIGN KEY (${StockMovementsTable.itemId})
          REFERENCES ${ItemsTable.tableName}(${ItemsTable.id}),
        FOREIGN KEY (${StockMovementsTable.transactionId})
          REFERENCES ${TransactionsTable.tableName}(${TransactionsTable.id})
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_transactions_business_date ON ${TransactionsTable.tableName}(${TransactionsTable.businessId}, ${TransactionsTable.date})',
    );
    await db.execute(
      'CREATE INDEX idx_journal_lines_account ON ${JournalLinesTable.tableName}(${JournalLinesTable.accountId})',
    );
    await db.execute(
      'CREATE INDEX idx_parties_business_balance ON ${PartiesTable.tableName}(${PartiesTable.businessId}, ${PartiesTable.balance})',
    );

    await AccountSeeder.seedAllBusinesses(db);

    await db.insert(
      'schema_meta',
      {'key': 'schema_version', 'value': '3'},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
