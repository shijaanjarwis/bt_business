import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/sale_entry.dart';
import '../repositories/sale_repository.dart';

final class SaveSaleUseCase implements UseCase<SaleEntry, SaveSaleInput> {
  const SaveSaleUseCase(this._repository);

  final SaleRepository _repository;

  @override
  Future<Result<SaleEntry>> call(SaveSaleInput input) async {
    final validationError = _validate(input);
    if (validationError != null) {
      return Error(validationError);
    }

    return _repository.saveSale(input);
  }

  Failure? _validate(SaveSaleInput input) {
    if (input.partyId.trim().isEmpty) {
      return const ValidationFailure('Grahak chuniye');
    }
    if (input.lines.isEmpty) {
      return const ValidationFailure('Kam se kam ek maal jodein');
    }

    for (final line in input.lines) {
      if (line.itemId.trim().isEmpty) {
        return const ValidationFailure('Har line mein maal hona chahiye');
      }
      if (line.qty <= 0) {
        return const ValidationFailure('Matra zero se zyada honi chahiye');
      }
      if (line.rate <= 0) {
        return const ValidationFailure('Daam zero se zyada hona chahiye');
      }
    }

    return null;
  }
}
