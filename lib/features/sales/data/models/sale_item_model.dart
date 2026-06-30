import '../../../items/data/models/item_model.dart';
import '../../../items/domain/entities/item.dart';

/// Backward-compatible alias used by purchase module until it is migrated.
typedef SaleItem = Item;

/// Maps SQLite rows to [Item] for purchase datasource compatibility.
final class SaleItemModel {
  const SaleItemModel({required this.item});

  final Item item;

  factory SaleItemModel.fromMap(Map<String, Object?> map) {
    return SaleItemModel(item: ItemModel.fromMap(map).item);
  }
}
