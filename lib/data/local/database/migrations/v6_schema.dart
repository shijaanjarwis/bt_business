import 'package:sqflite/sqflite.dart';

import '../seeders/cash_customer_seeder.dart';
import '../tables/accounting_tables.dart';
import 'migration.dart';

/// Schema v6 — partial payment columns, soft delete, audit fields, cash customer.
final class V6SchemaMigration implements Migration {
  @override
  int get version => 6;

  @override
  Future<void> up(Database db) async {
    await _addTransactionColumns(db);
    await _addPartyColumns(db);
    await _addAuditColumns(db);
    await _backfillPaidDue(db);
    await CashCustomerSeeder.seedAllBusinesses(db);

    await db.insert(
      'schema_meta',
      {'key': 'schema_version', 'value': '6'},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> _addTransactionColumns(Database db) async {
    await db.execute(
      'ALTER TABLE ${TransactionsTable.tableName} ADD COLUMN ${TransactionsTable.paidAmount} REAL NOT NULL DEFAULT 0',
    );
    await db.execute(
      'ALTER TABLE ${TransactionsTable.tableName} ADD COLUMN ${TransactionsTable.dueAmount} REAL NOT NULL DEFAULT 0',
    );
    await db.execute(
      'ALTER TABLE ${TransactionsTable.tableName} ADD COLUMN ${TransactionsTable.parentTransactionId} TEXT',
    );
    await db.execute(
      'ALTER TABLE ${TransactionsTable.tableName} ADD COLUMN ${TransactionsTable.deletedAt} TEXT',
    );
    await db.execute(
      'ALTER TABLE ${TransactionsTable.tableName} ADD COLUMN ${TransactionsTable.createdBy} TEXT',
    );
  }

  Future<void> _addPartyColumns(Database db) async {
    await db.execute(
      'ALTER TABLE ${PartiesTable.tableName} ADD COLUMN ${PartiesTable.isSystem} INTEGER NOT NULL DEFAULT 0',
    );
    await db.execute(
      'ALTER TABLE ${PartiesTable.tableName} ADD COLUMN ${PartiesTable.systemKey} TEXT',
    );
    await db.execute(
      'ALTER TABLE ${PartiesTable.tableName} ADD COLUMN ${PartiesTable.deletedAt} TEXT',
    );
    await db.execute(
      'ALTER TABLE ${PartiesTable.tableName} ADD COLUMN ${PartiesTable.createdBy} TEXT',
    );
  }

  Future<void> _addAuditColumns(Database db) async {
    await _addColumnsIfMissing(db, JournalLinesTable.tableName, {
      AuditColumns.createdAt: 'TEXT',
      AuditColumns.updatedAt: 'TEXT',
      AuditColumns.deletedAt: 'TEXT',
      AuditColumns.createdBy: 'TEXT',
    });
    await _addColumnsIfMissing(db, ItemsTable.tableName, {
      AuditColumns.deletedAt: 'TEXT',
      AuditColumns.createdBy: 'TEXT',
    });
    await _addColumnsIfMissing(db, TransactionLinesTable.tableName, {
      AuditColumns.createdAt: 'TEXT',
      AuditColumns.updatedAt: 'TEXT',
      AuditColumns.deletedAt: 'TEXT',
      AuditColumns.createdBy: 'TEXT',
    });
    await _addColumnsIfMissing(db, StockMovementsTable.tableName, {
      AuditColumns.createdAt: 'TEXT',
      AuditColumns.updatedAt: 'TEXT',
      AuditColumns.deletedAt: 'TEXT',
      AuditColumns.createdBy: 'TEXT',
    });
  }

  Future<void> _addColumnsIfMissing(
    Database db,
    String table,
    Map<String, String> columns,
  ) async {
    final existing = await db.rawQuery('PRAGMA table_info($table)');
    final names = existing.map((row) => row['name']! as String).toSet();
    for (final entry in columns.entries) {
      if (names.contains(entry.key)) continue;
      await db.execute(
        'ALTER TABLE $table ADD COLUMN ${entry.key} ${entry.value}',
      );
    }
  }

  Future<void> _backfillPaidDue(Database db) async {
    await db.execute('''
      UPDATE ${TransactionsTable.tableName}
      SET ${TransactionsTable.paidAmount} = ${TransactionsTable.totalAmount},
          ${TransactionsTable.dueAmount} = 0
      WHERE ${TransactionsTable.type} IN ('sale', 'purchase')
        AND ${TransactionsTable.paidAmount} = 0
        AND ${TransactionsTable.totalAmount} > 0
    ''');
  }
}
