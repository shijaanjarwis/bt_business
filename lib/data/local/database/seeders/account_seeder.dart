import 'package:sqflite/sqflite.dart';

import '../../../../core/accounting/account_types.dart';
import '../../../../core/utils/id_generator.dart';
import '../tables/accounting_tables.dart';
import '../../../../features/business/data/datasources/business_table.dart';

/// Seeds the default chart of accounts for a business.
abstract final class AccountSeeder {
  static Future<void> seedForBusiness(Database db, String businessId) async {
    final existing = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM ${AccountsTable.tableName} WHERE ${AccountsTable.businessId} = ?',
        [businessId],
      ),
    );

    if ((existing ?? 0) > 0) return;

    final now = DateTime.now().toIso8601String();
    final defaults = [
      (AccountTypes.cash, 'Cash in Hand'),
      (AccountTypes.bank, 'Bank Account'),
      (AccountTypes.sales, 'Sales'),
      (AccountTypes.purchase, 'Purchase'),
      (AccountTypes.receivable, 'Accounts Receivable'),
      (AccountTypes.payable, 'Accounts Payable'),
      (AccountTypes.stock, 'Stock'),
      (AccountTypes.expense, 'General Expenses'),
      (AccountTypes.equity, 'Opening Balance Equity'),
    ];

    final batch = db.batch();
    for (final (type, name) in defaults) {
      batch.insert(AccountsTable.tableName, {
        AccountsTable.id: IdGenerator.newId(),
        AccountsTable.businessId: businessId,
        AccountsTable.name: name,
        AccountsTable.type: type,
        AccountsTable.isSystem: 1,
        AccountsTable.createdAt: now,
      });
    }
    await batch.commit(noResult: true);
  }

  static Future<void> seedAllBusinesses(Database db) async {
    final businesses = await db.query(BusinessTable.tableName, columns: [BusinessTable.id]);
    for (final row in businesses) {
      await seedForBusiness(db, row[BusinessTable.id]! as String);
    }
  }
}
