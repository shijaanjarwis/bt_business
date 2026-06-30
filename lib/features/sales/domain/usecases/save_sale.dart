import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/validators.dart';
import '../entities/sale_invoice.dart';
import '../repositories/sale_repository.dart';

final class SaveSaleUseCase implements UseCase<SaleInvoice, SaveSaleInput> {
  const SaveSaleUseCase(this._repository);

  final SaleRepository _repository;

  @override
  Future<Result<SaleInvoice>> call(SaveSaleInput input) async {
    final validationError = _validate(input);
    if (validationError != null) {
      return Error(validationError);
    }

    return _repository.saveSale(input);
  }

  Failure? _validate(SaveSaleInput input) {
    if (input.partyId.trim().isEmpty) {
      return const ValidationFailure('Select a customer');
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
