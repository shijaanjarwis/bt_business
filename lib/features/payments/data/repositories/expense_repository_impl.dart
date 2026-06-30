import '../../../../core/errors/exception_mapper.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../../ledger/data/datasources/party_local_datasource.dart';
import '../../domain/repositories/expense_repository.dart';
import '../services/expense_posting_service.dart';

final class ExpenseRepositoryImpl implements ExpenseRepository {
  const ExpenseRepositoryImpl(
    this._localDataSource,
    this._postingService,
  );

  final PartyLocalDataSource _localDataSource;
  final ExpensePostingService _postingService;

  @override
  Future<Result<void>> recordExpense(RecordExpenseInput input) async {
    try {
      final businessId = await _localDataSource.currentBusinessId();
      if (businessId == null) {
        return const Error(
          ValidationFailure('Pehle apni dukaan ka naam set karein'),
        );
      }

      await _postingService.record(
        businessId: businessId,
        name: input.name,
        amount: input.amount,
        date: input.date,
        note: input.note,
      );
      return const Success(null);
    } catch (error, stackTrace) {
      return Error(ExceptionMapper.map(error, stackTrace));
    }
  }
}
