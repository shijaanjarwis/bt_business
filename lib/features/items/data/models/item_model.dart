import '../../../../data/local/database/tables/accounting_tables.dart';
import '../../domain/entities/item.dart';

/// Maps [Item] to SQLite rows, including legacy columns for internal compatibility.
final class ItemModel {
  const ItemModel({required this.item});

  final Item item;

  factory ItemModel.fromMap(Map<String, Object?> map) {
    return ItemModel(
      item: Item(
        id: map[ItemsTable.id]! as String,
        name: map[ItemsTable.name]! as String,
        unit: map[ItemsTable.unit]! as String,
        openingStock: (map[ItemsTable.qtyOnHand] as num?)?.toDouble() ?? 0,
        purchasePrice: (map[ItemsTable.purchaseRate] as num?)?.toDouble() ?? 0,
        salePrice: (map[ItemsTable.saleRate] as num?)?.toDouble() ?? 0,
        gstRate: (map[ItemsTable.gstRate] as num?)?.toDouble() ?? 0,
        hsnSac: map[ItemsTable.hsnSac] as String?,
        isActive: (map[ItemsTable.isActive] as int? ?? 1) == 1,
      ),
    );
  }

  Map<String, Object?> toMap({
    required String businessId,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) {
    return {
      ItemsTable.id: item.id,
      ItemsTable.businessId: businessId,
      ItemsTable.name: item.name,
      ItemsTable.unit: item.unit,
      ItemsTable.qtyOnHand: item.openingStock,
      ItemsTable.purchaseRate: item.purchasePrice,
      ItemsTable.saleRate: item.salePrice,
      ItemsTable.gstRate: item.gstRate,
      ItemsTable.hsnSac: item.hsnSac,
      ItemsTable.isActive: item.isActive ? 1 : 0,
      ItemsTable.createdAt: createdAt.toIso8601String(),
      ItemsTable.updatedAt: updatedAt.toIso8601String(),
    };
  }
}
