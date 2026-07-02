import 'package:bt_business/data/local/database/migrations/migration_runner.dart';
import 'package:bt_business/data/local/database/tables/accounting_tables.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('v7 migration adds reminder_date column', () async {
    final db = await openDatabase(
      inMemoryDatabasePath,
      version: 7,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: MigrationRunner.onCreate,
      onUpgrade: MigrationRunner.onUpgrade,
    );

    final columns = await db.rawQuery(
      'PRAGMA table_info(${TransactionsTable.tableName})',
    );
    final names = columns.map((row) => row['name'] as String).toList();
    expect(names, contains(TransactionsTable.reminderDate));

    await db.close();
  });
}
