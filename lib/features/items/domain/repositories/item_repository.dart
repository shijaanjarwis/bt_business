import '../../../../core/errors/result.dart';
import '../entities/item.dart';

/// Persistence contract for the flat item master.
abstract interface class ItemRepository {
  Future<Result<List<Item>>> searchItems(String query);

  Future<Result<Item?>> getItem(String id);

  Future<Result<Item?>> findByName(String name);

  Future<Result<Item>> saveItem(SaveItemInput input);
}

/// Input for creating or updating an item.
class SaveItemInput {
  const SaveItemInput({
    this.id,
    required this.name,
    required this.unit,
    required this.openingStock,
    required this.purchasePrice,
    required this.salePrice,
    required this.gstRate,
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
