import 'package:bt_business/data/local/database/migrations/migration_runner.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('v8 migration adds performance indexes', () async {
    final db = await openDatabase(
      inMemoryDatabasePath,
      version: 8,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: MigrationRunner.onCreate,
      onUpgrade: MigrationRunner.onUpgrade,
    );

    final indexes = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'index' AND name LIKE 'idx_%'",
    );
    final names = indexes.map((row) => row['name'] as String).toList();

    expect(names, contains('idx_parties_business_name'));
    expect(names, contains('idx_transactions_business_type_date'));
    expect(names, contains('idx_items_business_name'));

    await db.close();
  });
}
