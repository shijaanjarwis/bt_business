import 'package:bt_business/data/local/database/migrations/v1_initial.dart';
import 'package:bt_business/data/local/database/migrations/v2_business.dart';
import 'package:bt_business/data/local/database/migrations/v3_accounting.dart';
import 'package:bt_business/data/local/database/tables/accounting_tables.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('V3AccountingMigration creates accounting tables', () async {
    final db = await openDatabase(
      inMemoryDatabasePath,
      version: 2,
      onCreate: (database, version) async {
        await V1InitialMigration().up(database);
        await V2BusinessMigration().up(database);
      },
    );

    await V3AccountingMigration().up(db);

    final accounts = await db.rawQuery(
      'PRAGMA table_info(${AccountsTable.tableName})',
    );
    expect(accounts, isNotEmpty);

    await db.close();
  });
}
