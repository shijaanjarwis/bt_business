import '../../../../core/errors/result.dart';

/// Persistence contract for kharch entries.
abstract interface class ExpenseRepository {
  Future<Result<void>> recordExpense(RecordExpenseInput input);
}

class RecordExpenseInput {
  const RecordExpenseInput({
    required this.name,
    required this.amount,
    required this.date,
    this.note,
  });

  final String name;
  final double amount;
  final DateTime date;
  final String? note;
}
