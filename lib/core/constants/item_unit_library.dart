/// Searchable unit entry for the complete maal unit library.
class ItemUnitEntry {
  const ItemUnitEntry(this.name, this.category);

  final String name;
  final String category;
}

/// Complete unit library — presets plus full searchable list for "Other".
abstract final class ItemUnitLibrary {
  static const presets = [
    'Kg',
    'Packet',
    'Box',
    'Piece',
    'Litre',
    'Dozen',
    'Nos',
    'Meter',
  ];

  static const defaultUnit = 'Piece';

  static const all = <ItemUnitEntry>[
    // Weight
    ItemUnitEntry('Kg', 'Weight'),
    ItemUnitEntry('Gram', 'Weight'),
    ItemUnitEntry('Milligram', 'Weight'),
    ItemUnitEntry('Quintal', 'Weight'),
    ItemUnitEntry('Ton', 'Weight'),
    ItemUnitEntry('Tola', 'Weight'),
    ItemUnitEntry('Ratti', 'Weight'),
    ItemUnitEntry('Carat', 'Weight'),
    // Length
    ItemUnitEntry('Meter', 'Length'),
    ItemUnitEntry('Millimeter', 'Length'),
    ItemUnitEntry('Centimeter', 'Length'),
    ItemUnitEntry('Kilometer', 'Length'),
    ItemUnitEntry('Inch', 'Length'),
    ItemUnitEntry('Foot', 'Length'),
    ItemUnitEntry('Yard', 'Length'),
    // Area
    ItemUnitEntry('Square Foot', 'Area'),
    ItemUnitEntry('Square Meter', 'Area'),
    ItemUnitEntry('Acre', 'Area'),
    ItemUnitEntry('Bigha', 'Area'),
    // Volume
    ItemUnitEntry('Litre', 'Volume'),
    ItemUnitEntry('Millilitre', 'Volume'),
    // Count
    ItemUnitEntry('Piece', 'Count'),
    ItemUnitEntry('Packet', 'Count'),
    ItemUnitEntry('Box', 'Count'),
    ItemUnitEntry('Bundle', 'Count'),
    ItemUnitEntry('Dozen', 'Count'),
    ItemUnitEntry('Pair', 'Count'),
    ItemUnitEntry('Set', 'Count'),
    ItemUnitEntry('Roll', 'Count'),
    ItemUnitEntry('Bag', 'Count'),
    ItemUnitEntry('Sack', 'Count'),
    ItemUnitEntry('Bottle', 'Count'),
    ItemUnitEntry('Can', 'Count'),
    ItemUnitEntry('Drum', 'Count'),
    ItemUnitEntry('Sheet', 'Count'),
    ItemUnitEntry('Rod', 'Count'),
    ItemUnitEntry('Pipe', 'Count'),
    ItemUnitEntry('Nos', 'Count'),
    // Construction
    ItemUnitEntry('Cubic Foot', 'Construction'),
    ItemUnitEntry('Cubic Meter', 'Construction'),
    // Fabric (Meter, Yard already listed under Length)
    // Jewellery (Gram, Carat, Tola, Ratti already under Weight)
    // Agriculture (Quintal, Ton, Sack, Bag already listed)
  ];

  static List<ItemUnitEntry> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return all;
    return all
        .where(
          (entry) =>
              entry.name.toLowerCase().contains(q) ||
              entry.category.toLowerCase().contains(q),
        )
        .toList();
  }

  static List<String> get categories =>
      all.map((e) => e.category).toSet().toList()..sort();

  /// Whole-number qty for count units; decimals for weight/length/volume/etc.
  static bool allowsDecimalQuantity(String unitName) {
    final entry = _matchUnit(unitName);
    if (entry != null) {
      return entry.category != 'Count';
    }
    return false;
  }

  static ItemUnitEntry? _matchUnit(String unitName) {
    final normalized = unitName.trim().toLowerCase();
    if (normalized.isEmpty) return null;
    for (final entry in all) {
      if (entry.name.toLowerCase() == normalized) return entry;
    }
    return null;
  }

  static String formatQuantity(double qty, String unit) {
    final clamped = clampQuantity(qty, unit);
    if (allowsDecimalQuantity(unit)) {
      if (clamped == clamped.roundToDouble()) {
        return clamped.round().toString();
      }
      return clamped.toStringAsFixed(2);
    }
    return clamped.round().toString();
  }

  static double parseQuantity(String text, {required String unit, double fallback = 1}) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return fallback;
    final parsed = double.tryParse(trimmed);
    if (parsed == null) return fallback;
    return clampQuantity(parsed, unit);
  }

  static double clampQuantity(double qty, String unit) {
    const min = 1.0;
    const max = 999999.0;
    var value = qty.clamp(min, max).toDouble();
    if (!allowsDecimalQuantity(unit)) {
      value = value.roundToDouble();
    }
    return value;
  }
}
