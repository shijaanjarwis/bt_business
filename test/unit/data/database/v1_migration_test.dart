import 'package:bt_business/data/local/database/migrations/v1_initial.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('V1InitialMigration creates schema_meta table', () async {
    final db = await openDatabase(
      inMemoryDatabasePath,
      version: 1,
      onCreate: (database, version) async {
        await V1InitialMigration().up(database);
      },
    );

    final rows = await db.query('schema_meta');
    expect(rows, hasLength(1));
    expect(rows.first['key'], 'schema_version');
    expect(rows.first['value'], '1');

    await db.close();
  });
}
