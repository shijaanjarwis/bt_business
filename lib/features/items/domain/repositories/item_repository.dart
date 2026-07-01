import '../../../../core/errors/result.dart';
import '../entities/item.dart';

/// Persistence for Maal shortcuts (name, unit, optional default rates).
abstract interface class ItemRepository {
  Future<Result<List<Item>>> searchItems(String query);

  Future<Result<Item?>> getItem(String id);

  Future<Result<Item?>> findByName(String name);

  Future<Result<Item>> saveItem(SaveItemInput input);

  Future<Result<void>> deleteItem(String id);
}

/// Input for creating or updating a Maal shortcut.
///
/// [openingStock] and [gstRate] are legacy internal fields — not product fields.
/// UI must not collect or display them.
class SaveItemInput {
  const SaveItemInput({
    this.id,
    required this.name,
    required this.unit,
    this.openingStock = 0,
    this.purchasePrice = 0,
    this.salePrice = 0,
    this.gstRate = 0,
    this.existingCreatedAt,
  });

  final String? id;
  final String name;
  final String unit;
  final double openingStock;
  final double purchasePrice;
  final double salePrice;
  final double gstRate;
  final DateTime? existingCreatedAt;
}
