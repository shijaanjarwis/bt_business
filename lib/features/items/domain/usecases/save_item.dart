import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/validators.dart';
import '../entities/item.dart';
import '../repositories/item_repository.dart';

final class SaveItemUseCase implements UseCase<Item, SaveItemInput> {
  const SaveItemUseCase(this._repository);

  final ItemRepository _repository;

  @override
  Future<Result<Item>> call(SaveItemInput input) async {
    final validationError = _validate(input);
    if (validationError != null) {
      return Error(validationError);
    }

    if (input.id == null) {
      final existing = await _repository.findByName(input.name.trim());
      if (existing.isSuccess && existing.valueOrNull != null) {
        return const Error(
          ValidationFailure('An item with this name already exists'),
        );
      }
    }

    return _repository.saveItem(
      SaveItemInput(
        id: input.id,
        name: input.name.trim(),
        unit: input.unit.trim(),
        openingStock: input.openingStock,
        purchasePrice: input.purchasePrice,
        salePrice: input.salePrice,
        gstRate: input.gstRate,
        existingCreatedAt: input.existingCreatedAt,
      ),
    );
  }

  Failure? _validate(SaveItemInput input) {
    final nameError = Validators.requiredText(input.name, fieldName: 'Item name');
    if (nameError != null) return ValidationFailure(nameError);

    final unitError = Validators.requiredText(input.unit, fieldName: 'Unit');
    if (unitError != null) return ValidationFailure(unitError);

    if (input.openingStock < 0) {
      return const ValidationFailure('Opening stock cannot be negative');
    }
    if (input.purchasePrice < 0 || input.salePrice < 0) {
      return const ValidationFailure('Prices cannot be negative');
    }
    if (input.gstRate < 0 || input.gstRate > 100) {
      return const ValidationFailure('GST must be between 0 and 100');
    }

    return null;
  }
}
