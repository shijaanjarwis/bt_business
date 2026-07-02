import 'package:bt_business/core/accounting/gst_types.dart';
import 'package:bt_business/core/accounting/payment_modes.dart';
import 'package:bt_business/core/errors/failures.dart';
import 'package:bt_business/core/errors/result.dart';
import 'package:bt_business/features/purchase/domain/entities/purchase_invoice.dart';
import 'package:bt_business/features/purchase/domain/repositories/purchase_repository.dart';
import 'package:bt_business/features/purchase/domain/usecases/save_purchase.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakePurchaseRepository implements PurchaseRepository {
  @override
  Future<Result<List<PurchaseInvoice>>> getPurchases({
    DateTime? fromDate,
    DateTime? toDate,
    PaymentMode? paymentMode,
    double? minDueAmount,
    double? minPaidAmount,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Result<List<PurchaseInvoice>>> searchPurchases(
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
  Future<Result<PurchaseInvoice?>> getPurchase(String id) {
    throw UnimplementedError();
  }

  @override
  Future<Result<PurchaseInvoice>> savePurchase(SavePurchaseInput input) {
    throw UnimplementedError();
  }

  @override
  Future<Result<void>> deletePurchase(String id) {
    throw UnimplementedError();
  }
}

void main() {
  test('SavePurchaseUseCase validates supplier and lines', () async {
    final useCase = SavePurchaseUseCase(_FakePurchaseRepository());

    final result = await useCase(
      SavePurchaseInput(
        date: DateTime.now(),
        partyId: '',
        paymentMode: PaymentMode.cash,
        gstType: GstType.intra,
        lines: const [],
      ),
    );

    expect(result.isFailure, isTrue);
    expect(result.failureOrNull, isA<ValidationFailure>());
  });
}
