import 'package:bt_business/core/accounting/gst_types.dart';
import 'package:bt_business/core/accounting/payment_modes.dart';
import 'package:bt_business/core/errors/failures.dart';
import 'package:bt_business/core/errors/result.dart';
import 'package:bt_business/features/sales/domain/entities/sale_entry.dart';
import 'package:bt_business/features/sales/domain/repositories/sale_repository.dart';
import 'package:bt_business/features/sales/domain/usecases/save_sale.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeSaleRepository implements SaleRepository {
  SaveSaleInput? lastInput;

  @override
  Future<Result<List<SaleEntry>>> getSales({
    DateTime? fromDate,
    DateTime? toDate,
    PaymentMode? paymentMode,
    double? minDueAmount,
    double? minPaidAmount,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Result<List<SaleEntry>>> searchSales(
    String query, {
    DateTime? fromDate,
    DateTime? toDate,
    PaymentMode? paymentMode,
    double? minDueAmount,
    double? minPaidAmount,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Result<SaleEntry?>> getSale(String id) {
    throw UnimplementedError();
  }

  @override
  Future<Result<SaleEntry>> saveSale(SaveSaleInput input) async {
    lastInput = input;
    throw UnimplementedError();
  }

  @override
  Future<Result<void>> deleteSale(String id) {
    throw UnimplementedError();
  }
}

void main() {
  test('SaveSaleUseCase validates customer and lines', () async {
    final repository = _FakeSaleRepository();
    final useCase = SaveSaleUseCase(repository);

    final result = await useCase(
      SaveSaleInput(
        date: DateTime.now(),
        partyId: '',
        paymentMode: PaymentMode.cash,
        gstType: GstType.intra,
        lines: const [],
      ),
    );

    expect(result.isFailure, isTrue);
    expect(result.failureOrNull, isA<ValidationFailure>());
    expect(result.failureOrNull?.message, contains('Grahak'));
  });
}
