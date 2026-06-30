import '../../../../data/local/database/tables/accounting_tables.dart';

/// Catalog item available for sale lines.
class SaleItem {
  const SaleItem({
    required this.id,
    required this.name,
    required this.unit,
    required this.qtyOnHand,
    required this.purchaseRate,
    required this.saleRate,
    required this.gstRate,
    this.hsnSac,
    required this.isActive,
  });

  final String id;
  final String name;
  final String unit;
  final double qtyOnHand;
  final double purchaseRate;
  final double saleRate;
  final double gstRate;
  final String? hsnSac;
  final bool isActive;
}

/// Maps between [SaleItem] and SQLite rows.
final class SaleItemModel {
  const SaleItemModel({required this.item});

  final SaleItem item;

  factory SaleItemModel.fromMap(Map<String, Object?> map) {
    return SaleItemModel(
      item: SaleItem(
        id: map[ItemsTable.id]! as String,
        name: map[ItemsTable.name]! as String,
        unit: map[ItemsTable.unit]! as String,
        qtyOnHand: (map[ItemsTable.qtyOnHand] as num?)?.toDouble() ?? 0,
        purchaseRate: (map[ItemsTable.purchaseRate] as num?)?.toDouble() ?? 0,
        saleRate: (map[ItemsTable.saleRate] as num?)?.toDouble() ?? 0,
        gstRate: (map[ItemsTable.gstRate] as num?)?.toDouble() ?? 0,
        hsnSac: map[ItemsTable.hsnSac] as String?,
        isActive: (map[ItemsTable.isActive] as int? ?? 1) == 1,
      ),
    );
  }
}
