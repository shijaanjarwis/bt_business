/// A sale/purchase line-item shortcut — name, unit, and optional default rates.
///
/// Legacy DB-mapped fields ([openingStock], [gstRate], [hsnSac]) exist for
/// internal data compatibility only. Never show them in Item Master UI.
class Item {
  const Item({
    required this.id,
    required this.name,
    required this.unit,
    required this.openingStock,
    required this.purchasePrice,
    required this.salePrice,
    required this.gstRate,
    this.hsnSac,
    required this.isActive,
  });

  final String id;
  final String name;
  final String unit;
  final double openingStock;
  final double purchasePrice;
  final double salePrice;
  final double gstRate;
  final String? hsnSac;
  final bool isActive;

  /// Internal alias for legacy [ItemsTable.qtyOnHand] — not shown in UI.
  double get qtyOnHand => openingStock;
  double get purchaseRate => purchasePrice;
  double get saleRate => salePrice;

  Item copyWith({
    String? id,
    String? name,
    String? unit,
    double? openingStock,
    double? purchasePrice,
    double? salePrice,
    double? gstRate,
    String? hsnSac,
    bool? isActive,
  }) {
    return Item(
      id: id ?? this.id,
      name: name ?? this.name,
      unit: unit ?? this.unit,
      openingStock: openingStock ?? this.openingStock,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      salePrice: salePrice ?? this.salePrice,
      gstRate: gstRate ?? this.gstRate,
      hsnSac: hsnSac ?? this.hsnSac,
      isActive: isActive ?? this.isActive,
    );
  }
}
