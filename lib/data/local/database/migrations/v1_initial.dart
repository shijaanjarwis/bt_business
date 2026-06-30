import 'package:sqflite/sqflite.dart';

import 'migration.dart';

/// Foundation schema — business tables are added in later phases.
final class V1InitialMigration implements Migration {
  @override
  int get version => 1;

  @override
  Future<void> up(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS schema_meta (
        key TEXT PRIMARY KEY NOT NULL,
        value TEXT NOT NULL
      )
    ''');

    await db.insert(
      'schema_meta',
      {'key': 'schema_version', 'value': '1'},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
