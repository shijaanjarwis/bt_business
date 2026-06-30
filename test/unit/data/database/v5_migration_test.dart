import 'package:bt_business/data/local/database/migrations/v1_initial.dart';
import 'package:bt_business/data/local/database/migrations/v2_business.dart';
import 'package:bt_business/data/local/database/migrations/v3_accounting.dart';
import 'package:bt_business/data/local/database/migrations/v4_party_ledger.dart';
import 'package:bt_business/data/local/database/migrations/v5_sales.dart';
import 'package:bt_business/data/local/database/tables/accounting_tables.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('V5SalesMigration adds transaction lines and GST columns', () async {
    final db = await openDatabase(
      inMemoryDatabasePath,
      version: 4,
      onCreate: (database, version) async {
        await V1InitialMigration().up(database);
        await V2BusinessMigration().up(database);
        await V3AccountingMigration().up(database);
        await V4PartyLedgerMigration().up(database);
      },
    );

    await V5SalesMigration().up(db);

    final lineInfo = await db.rawQuery(
      'PRAGMA table_info(${TransactionLinesTable.tableName})',
    );
    expect(lineInfo, isNotEmpty);

    final txInfo = await db.rawQuery(
      'PRAGMA table_info(${TransactionsTable.tableName})',
    );
    final txColumns = txInfo.map((row) => row['name'] as String).toSet();
    expect(txColumns, contains(TransactionsTable.paymentMode));
    expect(txColumns, contains(TransactionsTable.cgstTotal));

    await db.close();
  });
}
