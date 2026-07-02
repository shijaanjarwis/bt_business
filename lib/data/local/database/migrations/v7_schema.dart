import 'package:sqflite/sqflite.dart';

import '../tables/accounting_tables.dart';
import 'migration.dart';

/// Schema v7 — optional next reminder date on every register transaction.
final class V7SchemaMigration implements Migration {
  @override
  int get version => 7;

  @override
  Future<void> up(Database db) async {
    await db.execute(
      'ALTER TABLE ${TransactionsTable.tableName} ADD COLUMN ${TransactionsTable.reminderDate} TEXT',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_transactions_reminder_date ON ${TransactionsTable.tableName}(${TransactionsTable.businessId}, ${TransactionsTable.reminderDate})',
    );

    await db.insert(
      'schema_meta',
      {'key': 'schema_version', 'value': '7'},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
