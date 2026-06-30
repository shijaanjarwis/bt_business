import 'package:bt_business/core/errors/failures.dart';
import 'package:bt_business/core/errors/result.dart';
import 'package:bt_business/features/items/domain/entities/item.dart';
import 'package:bt_business/features/items/domain/repositories/item_repository.dart';
import 'package:bt_business/features/items/domain/usecases/save_item.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeItemRepository implements ItemRepository {
  SaveItemInput? lastInput;
  Item? existingByName;

  @override
  Future<Result<List<Item>>> searchItems(String query) {
    throw UnimplementedError();
  }

  @override
  Future<Result<Item?>> getItem(String id) {
    throw UnimplementedError();
  }

  @override
  Future<Result<Item?>> findByName(String name) async {
    return Success(existingByName);
  }

  @override
  Future<Result<Item>> saveItem(SaveItemInput input) async {
    lastInput = input;
    return Success(
      Item(
        id: 'item-1',
        name: input.name,
        unit: input.unit,
        openingStock: input.openingStock,
        purchasePrice: input.purchasePrice,
        salePrice: input.salePrice,
        gstRate: input.gstRate,
        isActive: true,
      ),
    );
  }
}

void main() {
  test('SaveItemUseCase validates required fields', () async {
    final repository = _FakeItemRepository();
    final useCase = SaveItemUseCase(repository);

    final result = await useCase(
      const SaveItemInput(
        name: '',
        unit: 'pcs',
        openingStock: 0,
        purchasePrice: 0,
        salePrice: 0,
        gstRate: 18,
      ),
    );

    expect(result.isFailure, isTrue);
    expect(result.failureOrNull, isA<ValidationFailure>());
  });

  test('SaveItemUseCase rejects duplicate names', () async {
    final repository = _FakeItemRepository()
      ..existingByName = const Item(
        id: 'existing',
        name: 'Sugar',
        unit: 'kg',
        openingStock: 10,
        purchasePrice: 40,
        salePrice: 50,
        gstRate: 5,
        isActive: true,
      );
    final useCase = SaveItemUseCase(repository);

    final result = await useCase(
      const SaveItemInput(
        name: 'Sugar',
        unit: 'kg',
        openingStock: 0,
        purchasePrice: 40,
        salePrice: 50,
        gstRate: 5,
      ),
    );

    expect(result.isFailure, isTrue);
    expect(result.failureOrNull?.message, contains('already exists'));
  });

  test('SaveItemUseCase trims name and unit', () async {
    final repository = _FakeItemRepository();
    final useCase = SaveItemUseCase(repository);

    final result = await useCase(
      const SaveItemInput(
        name: '  Rice  ',
        unit: '  kg ',
        openingStock: 5,
        purchasePrice: 60,
        salePrice: 70,
        gstRate: 0,
      ),
    );

    expect(result.isSuccess, isTrue);
    expect(repository.lastInput?.name, 'Rice');
    expect(repository.lastInput?.unit, 'kg');
  });
}
