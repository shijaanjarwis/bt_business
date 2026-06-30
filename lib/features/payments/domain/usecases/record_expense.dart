import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/expense_repository.dart';

final class RecordExpenseUseCase implements UseCase<void, RecordExpenseInput> {
  const RecordExpenseUseCase(this._repository);

  final ExpenseRepository _repository;

  @override
  Future<Result<void>> call(RecordExpenseInput input) async {
    if (input.name.trim().isEmpty) {
      return const Error(ValidationFailure('Kharch ka naam likhiye'));
    }
    if (input.amount <= 0) {
      return const Error(ValidationFailure('Raashi zero se zyada honi chahiye'));
    }
    return _repository.recordExpense(input);
  }
}
