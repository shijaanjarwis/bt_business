import 'package:sqflite/sqflite.dart';

import '../../../../features/business/data/datasources/business_table.dart';
import 'migration.dart';

/// Adds the business profile table for single-business-per-device storage.
final class V2BusinessMigration implements Migration {
  @override
  int get version => 2;

  @override
  Future<void> up(Database db) async {
    await db.execute('''
      CREATE TABLE ${BusinessTable.tableName} (
        ${BusinessTable.id} TEXT PRIMARY KEY NOT NULL,
        ${BusinessTable.name} TEXT NOT NULL,
        ${BusinessTable.address} TEXT NOT NULL DEFAULT '',
        ${BusinessTable.phone} TEXT NOT NULL DEFAULT '',
        ${BusinessTable.email} TEXT NOT NULL DEFAULT '',
        ${BusinessTable.gstin} TEXT,
        ${BusinessTable.logoPath} TEXT,
        ${BusinessTable.financialYearStartMonth} INTEGER NOT NULL DEFAULT 4,
        ${BusinessTable.currencyCode} TEXT NOT NULL DEFAULT 'INR',
        ${BusinessTable.createdAt} TEXT NOT NULL,
        ${BusinessTable.updatedAt} TEXT NOT NULL
      )
    ''');

    await db.insert(
      'schema_meta',
      {'key': 'schema_version', 'value': '2'},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
