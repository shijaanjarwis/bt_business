import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/validators.dart';
import '../entities/purchase_invoice.dart';
import '../repositories/purchase_repository.dart';

final class SavePurchaseUseCase implements UseCase<PurchaseInvoice, SavePurchaseInput> {
  const SavePurchaseUseCase(this._repository);

  final PurchaseRepository _repository;

  @override
  Future<Result<PurchaseInvoice>> call(SavePurchaseInput input) async {
    final validationError = _validate(input);
    if (validationError != null) {
      return Error(validationError);
    }

    return _repository.savePurchase(input);
  }

  Failure? _validate(SavePurchaseInput input) {
    if (input.partyId.trim().isEmpty) {
      return const ValidationFailure('Select a supplier');
    }
    if (input.lines.isEmpty) {
      return const ValidationFailure('Add at least one product line');
    }

    for (final line in input.lines) {
      if (line.itemId.trim().isEmpty) {
        return const ValidationFailure('Each line must have a product');
      }
      if (line.qty <= 0) {
        return const ValidationFailure('Quantity must be greater than zero');
      }
      if (line.rate <= 0) {
        return const ValidationFailure('Rate must be greater than zero');
      }
      if (line.discountAmount < 0) {
        return const ValidationFailure('Discount cannot be negative');
      }
      final gstError = Validators.nonNegativeAmount(
        line.gstRate.toString(),
        fieldName: 'GST rate',
      );
      if (gstError != null) return ValidationFailure(gstError);
    }

    return null;
  }
}
