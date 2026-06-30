import 'package:bt_business/core/errors/failures.dart';
import 'package:bt_business/core/errors/result.dart';
import 'package:bt_business/features/payments/domain/repositories/expense_repository.dart';
import 'package:bt_business/features/payments/domain/usecases/record_expense.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeExpenseRepository implements ExpenseRepository {
  RecordExpenseInput? lastInput;

  @override
  Future<Result<void>> recordExpense(RecordExpenseInput input) async {
    lastInput = input;
    return const Success(null);
  }
}

void main() {
  test('RecordExpenseUseCase validates name and amount', () async {
    final repository = _FakeExpenseRepository();
    final useCase = RecordExpenseUseCase(repository);

    final emptyName = await useCase(
      RecordExpenseInput(
        name: '',
        amount: 100,
        date: DateTime.now(),
      ),
    );
    expect(emptyName.isFailure, isTrue);
    expect(emptyName.failureOrNull, isA<ValidationFailure>());

    final zeroAmount = await useCase(
      RecordExpenseInput(
        name: 'Tea',
        amount: 0,
        date: DateTime.now(),
      ),
    );
    expect(zeroAmount.isFailure, isTrue);
  });

  test('RecordExpenseUseCase saves valid kharch', () async {
    final repository = _FakeExpenseRepository();
    final useCase = RecordExpenseUseCase(repository);

    final result = await useCase(
      RecordExpenseInput(
        name: 'Rent',
        amount: 5000,
        date: DateTime(2026, 6, 30),
        note: 'Shop rent',
      ),
    );

    expect(result.isSuccess, isTrue);
    expect(repository.lastInput?.name, 'Rent');
    expect(repository.lastInput?.note, 'Shop rent');
  });
}
