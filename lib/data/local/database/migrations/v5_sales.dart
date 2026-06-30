import 'package:sqflite/sqflite.dart';

import '../../../../core/accounting/account_types.dart';
import '../../../../core/utils/id_generator.dart';
import '../../../../features/business/data/datasources/business_table.dart';
import '../tables/accounting_tables.dart';
import 'migration.dart';

/// Adds sales invoice lines, GST fields, and GST liability accounts.
final class V5SalesMigration implements Migration {
  @override
  int get version => 5;

  @override
  Future<void> up(Database db) async {
    await db.execute(
      'ALTER TABLE ${TransactionsTable.tableName} ADD COLUMN ${TransactionsTable.paymentMode} TEXT NOT NULL DEFAULT \'cash\'',
    );
    await db.execute(
      'ALTER TABLE ${TransactionsTable.tableName} ADD COLUMN ${TransactionsTable.gstType} TEXT NOT NULL DEFAULT \'intra\'',
    );
    await db.execute(
      'ALTER TABLE ${TransactionsTable.tableName} ADD COLUMN ${TransactionsTable.subtotal} REAL NOT NULL DEFAULT 0',
    );
    await db.execute(
      'ALTER TABLE ${TransactionsTable.tableName} ADD COLUMN ${TransactionsTable.discountTotal} REAL NOT NULL DEFAULT 0',
    );
    await db.execute(
      'ALTER TABLE ${TransactionsTable.tableName} ADD COLUMN ${TransactionsTable.taxableTotal} REAL NOT NULL DEFAULT 0',
    );
    await db.execute(
      'ALTER TABLE ${TransactionsTable.tableName} ADD COLUMN ${TransactionsTable.cgstTotal} REAL NOT NULL DEFAULT 0',
    );
    await db.execute(
      'ALTER TABLE ${TransactionsTable.tableName} ADD COLUMN ${TransactionsTable.sgstTotal} REAL NOT NULL DEFAULT 0',
    );
    await db.execute(
      'ALTER TABLE ${TransactionsTable.tableName} ADD COLUMN ${TransactionsTable.igstTotal} REAL NOT NULL DEFAULT 0',
    );

    await db.execute(
      'ALTER TABLE ${ItemsTable.tableName} ADD COLUMN ${ItemsTable.gstRate} REAL NOT NULL DEFAULT 0',
    );
    await db.execute(
      'ALTER TABLE ${ItemsTable.tableName} ADD COLUMN ${ItemsTable.hsnSac} TEXT',
    );
    await db.execute(
      'ALTER TABLE ${ItemsTable.tableName} ADD COLUMN ${ItemsTable.isActive} INTEGER NOT NULL DEFAULT 1',
    );

    await db.execute('''
      CREATE TABLE ${TransactionLinesTable.tableName} (
        ${TransactionLinesTable.id} TEXT PRIMARY KEY NOT NULL,
        ${TransactionLinesTable.transactionId} TEXT NOT NULL,
        ${TransactionLinesTable.itemId} TEXT NOT NULL,
        ${TransactionLinesTable.itemName} TEXT NOT NULL,
        ${TransactionLinesTable.hsnSac} TEXT,
        ${TransactionLinesTable.qty} REAL NOT NULL,
        ${TransactionLinesTable.rate} REAL NOT NULL,
        ${TransactionLinesTable.discountAmount} REAL NOT NULL DEFAULT 0,
        ${TransactionLinesTable.gstRate} REAL NOT NULL DEFAULT 0,
        ${TransactionLinesTable.taxableAmount} REAL NOT NULL DEFAULT 0,
        ${TransactionLinesTable.cgstAmount} REAL NOT NULL DEFAULT 0,
        ${TransactionLinesTable.sgstAmount} REAL NOT NULL DEFAULT 0,
        ${TransactionLinesTable.igstAmount} REAL NOT NULL DEFAULT 0,
        ${TransactionLinesTable.lineTotal} REAL NOT NULL DEFAULT 0,
        ${TransactionLinesTable.sortOrder} INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (${TransactionLinesTable.transactionId})
          REFERENCES ${TransactionsTable.tableName}(${TransactionsTable.id}),
        FOREIGN KEY (${TransactionLinesTable.itemId})
          REFERENCES ${ItemsTable.tableName}(${ItemsTable.id})
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_transaction_lines_tx ON ${TransactionLinesTable.tableName}(${TransactionLinesTable.transactionId})',
    );
    await db.execute(
      'CREATE INDEX idx_transactions_business_type ON ${TransactionsTable.tableName}(${TransactionsTable.businessId}, ${TransactionsTable.type})',
    );

    await _seedGstAccounts(db);

    await db.insert(
      'schema_meta',
      {'key': 'schema_version', 'value': '5'},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> _seedGstAccounts(Database db) async {
    final businesses = await db.query(BusinessTable.tableName, columns: [BusinessTable.id]);
    final now = DateTime.now().toIso8601String();
    final gstAccounts = [
      (AccountTypes.cgstPayable, 'CGST Payable'),
      (AccountTypes.sgstPayable, 'SGST Payable'),
      (AccountTypes.igstPayable, 'IGST Payable'),
      (AccountTypes.cogs, 'Cost of Goods Sold'),
    ];

    for (final row in businesses) {
      final businessId = row[BusinessTable.id]! as String;
      for (final (type, name) in gstAccounts) {
        final existing = Sqflite.firstIntValue(
          await db.rawQuery(
            '''
            SELECT COUNT(*)
            FROM ${AccountsTable.tableName}
            WHERE ${AccountsTable.businessId} = ? AND ${AccountsTable.type} = ?
            ''',
            [businessId, type],
          ),
        );
        if ((existing ?? 0) > 0) continue;

        await db.insert(AccountsTable.tableName, {
          AccountsTable.id: IdGenerator.newId(),
          AccountsTable.businessId: businessId,
          AccountsTable.name: name,
          AccountsTable.type: type,
          AccountsTable.isSystem: 1,
          AccountsTable.createdAt: now,
        });
      }
    }
  }
}
