import 'package:bt_business/data/local/database/migrations/v1_initial.dart';
import 'package:bt_business/data/local/database/migrations/v2_business.dart';
import 'package:bt_business/features/business/data/datasources/business_table.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('V2BusinessMigration creates business table', () async {
    final db = await openDatabase(
      inMemoryDatabasePath,
      version: 1,
      onCreate: (database, version) async {
        await V1InitialMigration().up(database);
      },
    );

    await V2BusinessMigration().up(db);

    final columns = await db.rawQuery(
      'PRAGMA table_info(${BusinessTable.tableName})',
    );

    expect(columns.map((column) => column['name']), contains(BusinessTable.name));
    expect(columns.map((column) => column['name']), contains(BusinessTable.gstin));

    await db.close();
  });
}
