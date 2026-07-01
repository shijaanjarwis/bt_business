import 'package:sqflite/sqflite.dart';

import '../../../../core/accounting/party_system_keys.dart';
import '../../../../core/utils/id_generator.dart';
import '../../../../features/business/data/datasources/business_table.dart';
import '../tables/accounting_tables.dart';

/// Seeds the built-in walk-in customer party for a business.
abstract final class CashCustomerSeeder {
  static const String displayName = 'Cash Customer';

  static Future<String> seedForBusiness(Database db, String businessId) async {
    final existing = await db.query(
      PartiesTable.tableName,
      columns: [PartiesTable.id],
      where:
          '${PartiesTable.businessId} = ? AND ${PartiesTable.systemKey} = ?',
      whereArgs: [businessId, PartySystemKeys.cashCustomer],
      limit: 1,
    );
    if (existing.isNotEmpty) {
      return existing.first[PartiesTable.id]! as String;
    }

    final now = DateTime.now().toIso8601String();
    final id = IdGenerator.newId();
    await db.insert(PartiesTable.tableName, {
      PartiesTable.id: id,
      PartiesTable.businessId: businessId,
      PartiesTable.name: displayName,
      PartiesTable.type: 'both',
      PartiesTable.phone: '',
      PartiesTable.address: '',
      PartiesTable.openingBalance: 0,
      PartiesTable.isActive: 1,
      PartiesTable.balance: 0,
      PartiesTable.isSystem: 1,
      PartiesTable.systemKey: PartySystemKeys.cashCustomer,
      PartiesTable.createdAt: now,
      PartiesTable.updatedAt: now,
    });
    return id;
  }

  static Future<void> seedAllBusinesses(Database db) async {
    final businesses = await db.query(
      BusinessTable.tableName,
      columns: [BusinessTable.id],
    );
    for (final row in businesses) {
      await seedForBusiness(db, row[BusinessTable.id]! as String);
    }
  }

  static Future<String?> idForBusiness(Database db, String businessId) async {
    final rows = await db.query(
      PartiesTable.tableName,
      columns: [PartiesTable.id],
      where:
          '${PartiesTable.businessId} = ? AND ${PartiesTable.systemKey} = ?',
      whereArgs: [businessId, PartySystemKeys.cashCustomer],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first[PartiesTable.id] as String;
  }
}
