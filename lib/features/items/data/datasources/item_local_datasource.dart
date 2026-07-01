import 'package:sqflite/sqflite.dart';

import '../../../../data/local/database/tables/accounting_tables.dart';
import '../../../../features/business/data/datasources/business_table.dart';
import '../../domain/entities/item.dart';
import '../models/item_model.dart';

/// SQLite operations for the flat item master.
final class ItemLocalDataSource {
  const ItemLocalDataSource(this._db);

  final Database _db;

  Future<String?> currentBusinessId() async {
    final rows = await _db.query(BusinessTable.tableName, limit: 1);
    if (rows.isEmpty) return null;
    return rows.first[BusinessTable.id] as String;
  }

  Future<List<Item>> searchItems(String query) async {
    final businessId = await currentBusinessId();
    if (businessId == null) return [];

    final trimmed = query.trim();
    final where = StringBuffer(
      '${ItemsTable.businessId} = ? AND ${ItemsTable.isActive} = 1 AND ${ItemsTable.deletedAt} IS NULL',
    );
    final args = <Object?>[businessId];

    if (trimmed.isNotEmpty) {
      where.write(
        ' AND (${ItemsTable.name} LIKE ? OR ${ItemsTable.unit} LIKE ?)',
      );
      args.add('%$trimmed%');
      args.add('%$trimmed%');
    }

    final rows = await _db.query(
      ItemsTable.tableName,
      where: where.toString(),
      whereArgs: args,
      orderBy: '${ItemsTable.name} COLLATE NOCASE ASC',
      limit: trimmed.isEmpty ? 500 : 50,
    );

    return rows.map((row) => ItemModel.fromMap(row).item).toList();
  }

  Future<Item?> fetchItem(String id) async {
    final rows = await _db.query(
      ItemsTable.tableName,
      where: '${ItemsTable.id} = ? AND ${ItemsTable.deletedAt} IS NULL',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return ItemModel.fromMap(rows.first).item;
  }

  Future<Item?> findByName(String name) async {
    final businessId = await currentBusinessId();
    if (businessId == null) return null;

    final rows = await _db.query(
      ItemsTable.tableName,
      where:
          '${ItemsTable.businessId} = ? AND LOWER(${ItemsTable.name}) = LOWER(?) AND ${ItemsTable.deletedAt} IS NULL',
      whereArgs: [businessId, name.trim()],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return ItemModel.fromMap(rows.first).item;
  }

  Future<Item> upsertItem(Item item, {DateTime? existingCreatedAt}) async {
    final businessId = await currentBusinessId();
    if (businessId == null) {
      throw StateError('Business profile required before saving items');
    }

    final now = DateTime.now();
    await _db.insert(
      ItemsTable.tableName,
      ItemModel(item: item).toMap(
        businessId: businessId,
        createdAt: existingCreatedAt ?? now,
        updatedAt: now,
      ),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return item;
  }

  Future<void> softDeleteItem(String id) async {
    final now = DateTime.now().toIso8601String();
    final updated = await _db.update(
      ItemsTable.tableName,
      {
        ItemsTable.isActive: 0,
        ItemsTable.deletedAt: now,
        ItemsTable.updatedAt: now,
      },
      where: '${ItemsTable.id} = ?',
      whereArgs: [id],
    );
    if (updated == 0) {
      throw StateError('Item not found');
    }
  }
}
