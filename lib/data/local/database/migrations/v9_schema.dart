import 'package:sqflite/sqflite.dart';

import '../../../../core/accounting/account_types.dart';
import '../../../../core/accounting/transaction_types.dart';
import '../../../../core/utils/id_generator.dart';
import '../../../../features/business/data/datasources/business_table.dart';
import '../tables/accounting_tables.dart';
import 'migration.dart';

/// Schema v9 — payment breakdown columns and UPI account.
final class V9SchemaMigration implements Migration {
  @override
  int get version => 9;

  @override
  Future<void> up(Database db) async {
    for (final column in [
      TransactionsTable.cashAmount,
      TransactionsTable.upiAmount,
      TransactionsTable.bankAmount,
      TransactionsTable.chequeAmount,
    ]) {
      await _addColumnIfMissing(db, column);
    }

    await db.execute(
      '''
      UPDATE ${TransactionsTable.tableName}
      SET ${TransactionsTable.cashAmount} = ${TransactionsTable.paidAmount}
      WHERE ${TransactionsTable.paidAmount} > 0
        AND ${TransactionsTable.cashAmount} = 0
        AND ${TransactionsTable.type} IN (?, ?)
      ''',
      [TransactionTypes.sale, TransactionTypes.purchase],
    );

    await _seedUpiAccounts(db);

    await db.insert(
      'schema_meta',
      {'key': 'schema_version', 'value': '9'},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> _addColumnIfMissing(Database db, String column) async {
    final columns = await db.rawQuery('PRAGMA table_info(${TransactionsTable.tableName})');
    final exists = columns.any((row) => row['name'] == column);
    if (exists) return;

    await db.execute(
      'ALTER TABLE ${TransactionsTable.tableName} ADD COLUMN $column REAL NOT NULL DEFAULT 0',
    );
  }

  Future<void> _seedUpiAccounts(Database db) async {
    final businesses = await db.query(BusinessTable.tableName, columns: [BusinessTable.id]);
    final now = DateTime.now().toIso8601String();

    for (final business in businesses) {
      final businessId = business[BusinessTable.id]! as String;
      final existing = Sqflite.firstIntValue(
        await db.rawQuery(
          '''
          SELECT COUNT(*)
          FROM ${AccountsTable.tableName}
          WHERE ${AccountsTable.businessId} = ?
            AND ${AccountsTable.type} = ?
          ''',
          [businessId, AccountTypes.upi],
        ),
      );
      if ((existing ?? 0) > 0) continue;

      await db.insert(AccountsTable.tableName, {
        AccountsTable.id: IdGenerator.newId(),
        AccountsTable.businessId: businessId,
        AccountsTable.name: 'UPI',
        AccountsTable.type: AccountTypes.upi,
        AccountsTable.isSystem: 1,
        AccountsTable.createdAt: now,
      });
    }
  }
}
