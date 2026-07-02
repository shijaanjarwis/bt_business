import 'package:sqflite/sqflite.dart';

import '../tables/accounting_tables.dart';
import 'migration.dart';

/// Schema v8 — performance indexes for large registers and instant search.
final class V8SchemaMigration implements Migration {
  @override
  int get version => 8;

  @override
  Future<void> up(Database db) async {
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_parties_business_name ON ${PartiesTable.tableName}(${PartiesTable.businessId}, ${PartiesTable.name} COLLATE NOCASE)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_parties_business_phone ON ${PartiesTable.tableName}(${PartiesTable.businessId}, ${PartiesTable.phone})',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_transactions_business_type_date ON ${TransactionsTable.tableName}(${TransactionsTable.businessId}, ${TransactionsTable.type}, ${TransactionsTable.date} DESC, ${TransactionsTable.createdAt} DESC)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_transactions_party_date ON ${TransactionsTable.tableName}(${TransactionsTable.partyId}, ${TransactionsTable.date}, ${TransactionsTable.createdAt})',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_transactions_due_amount ON ${TransactionsTable.tableName}(${TransactionsTable.businessId}, ${TransactionsTable.dueAmount})',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_items_business_name ON ${ItemsTable.tableName}(${ItemsTable.businessId}, ${ItemsTable.name} COLLATE NOCASE)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_transaction_lines_item_name ON ${TransactionLinesTable.tableName}(${TransactionLinesTable.itemName})',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_journal_lines_transaction ON ${JournalLinesTable.tableName}(${JournalLinesTable.transactionId})',
    );

    await db.insert(
      'schema_meta',
      {'key': 'schema_version', 'value': '8'},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
