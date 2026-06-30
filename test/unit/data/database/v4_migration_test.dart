import 'package:bt_business/data/local/database/migrations/v1_initial.dart';
import 'package:bt_business/data/local/database/migrations/v2_business.dart';
import 'package:bt_business/data/local/database/migrations/v3_accounting.dart';
import 'package:bt_business/data/local/database/migrations/v4_party_ledger.dart';
import 'package:bt_business/data/local/database/tables/accounting_tables.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('V4PartyLedgerMigration adds ledger columns to parties', () async {
    final db = await openDatabase(
      inMemoryDatabasePath,
      version: 3,
      onCreate: (database, version) async {
        await V1InitialMigration().up(database);
        await V2BusinessMigration().up(database);
        await V3AccountingMigration().up(database);
      },
    );

    await V4PartyLedgerMigration().up(db);

    final columns = await db.rawQuery(
      'PRAGMA table_info(${PartiesTable.tableName})',
    );
    final names = columns.map((row) => row['name'] as String).toSet();

    expect(names, contains(PartiesTable.address));
    expect(names, contains(PartiesTable.gstin));
    expect(names, contains(PartiesTable.creditLimit));
    expect(names, contains(PartiesTable.openingBalance));
    expect(names, contains(PartiesTable.isActive));
    expect(names, contains(PartiesTable.openingTransactionId));

    await db.close();
  });
}
