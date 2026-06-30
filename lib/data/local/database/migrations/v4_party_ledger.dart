import 'package:sqflite/sqflite.dart';

import '../tables/accounting_tables.dart';
import 'migration.dart';

/// Extends parties with ledger profile fields for customers and suppliers.
final class V4PartyLedgerMigration implements Migration {
  @override
  int get version => 4;

  @override
  Future<void> up(Database db) async {
    await db.execute(
      'ALTER TABLE ${PartiesTable.tableName} ADD COLUMN ${PartiesTable.address} TEXT NOT NULL DEFAULT \'\'',
    );
    await db.execute(
      'ALTER TABLE ${PartiesTable.tableName} ADD COLUMN ${PartiesTable.gstin} TEXT',
    );
    await db.execute(
      'ALTER TABLE ${PartiesTable.tableName} ADD COLUMN ${PartiesTable.creditLimit} REAL',
    );
    await db.execute(
      'ALTER TABLE ${PartiesTable.tableName} ADD COLUMN ${PartiesTable.openingBalance} REAL NOT NULL DEFAULT 0',
    );
    await db.execute(
      'ALTER TABLE ${PartiesTable.tableName} ADD COLUMN ${PartiesTable.isActive} INTEGER NOT NULL DEFAULT 1',
    );
    await db.execute(
      'ALTER TABLE ${PartiesTable.tableName} ADD COLUMN ${PartiesTable.openingTransactionId} TEXT',
    );

    await db.insert(
      'schema_meta',
      {'key': 'schema_version', 'value': '4'},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
