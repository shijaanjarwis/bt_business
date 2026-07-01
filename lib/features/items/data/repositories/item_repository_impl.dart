import '../../../../core/errors/exception_mapper.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/utils/id_generator.dart';
import '../../domain/entities/item.dart';
import '../../domain/repositories/item_repository.dart';
import '../datasources/item_local_datasource.dart';

final class ItemRepositoryImpl implements ItemRepository {
  const ItemRepositoryImpl(this._localDataSource);

  final ItemLocalDataSource _localDataSource;

  @override
  Future<Result<List<Item>>> searchItems(String query) async {
    try {
      final items = await _localDataSource.searchItems(query);
      return Success(items);
    } catch (error, stackTrace) {
      return Error(ExceptionMapper.map(error, stackTrace));
    }
  }

  @override
  Future<Result<Item?>> getItem(String id) async {
    try {
      final item = await _localDataSource.fetchItem(id);
      return Success(item);
    } catch (error, stackTrace) {
      return Error(ExceptionMapper.map(error, stackTrace));
    }
  }

  @override
  Future<Result<Item?>> findByName(String name) async {
    try {
      final item = await _localDataSource.findByName(name);
      return Success(item);
    } catch (error, stackTrace) {
      return Error(ExceptionMapper.map(error, stackTrace));
    }
  }

  @override
  Future<Result<Item>> saveItem(SaveItemInput input) async {
    try {
      final businessId = await _localDataSource.currentBusinessId();
      if (businessId == null) {
        return const Error(
          ValidationFailure('Set up your business profile before adding items'),
        );
      }

      var openingStock = input.openingStock;
      var gstRate = input.gstRate;
      if (input.id != null) {
        final existing = await _localDataSource.fetchItem(input.id!);
        if (existing != null) {
          // Preserve legacy internal row data — not exposed in Item Master UI.
          openingStock = existing.openingStock;
          gstRate = existing.gstRate;
        }
      }

      final item = Item(
        id: input.id ?? IdGenerator.newId(),
        name: input.name,
        unit: input.unit,
        openingStock: openingStock,
        purchasePrice: input.purchasePrice,
        salePrice: input.salePrice,
        gstRate: gstRate,
        isActive: true,
      );

      final saved = await _localDataSource.upsertItem(
        item,
        existingCreatedAt: input.existingCreatedAt,
      );
      return Success(saved);
    } catch (error, stackTrace) {
      return Error(ExceptionMapper.map(error, stackTrace));
    }
  }

  @override
  Future<Result<void>> deleteItem(String id) async {
    try {
      final item = await _localDataSource.fetchItem(id);
      if (item == null) {
        return const Error(ValidationFailure('Item not found'));
      }

      await _localDataSource.softDeleteItem(id);
      return const Success(null);
    } catch (error, stackTrace) {
      return Error(ExceptionMapper.map(error, stackTrace));
    }
  }
}
