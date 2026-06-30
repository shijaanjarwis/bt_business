import '../../../../core/accounting/payment_modes.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/purchase_invoice.dart';
import '../repositories/purchase_repository.dart';

final class GetPurchasesUseCase implements UseCase<List<PurchaseInvoice>, GetPurchasesParams> {
  const GetPurchasesUseCase(this._repository);

  final PurchaseRepository _repository;

  @override
  Future<Result<List<PurchaseInvoice>>> call(GetPurchasesParams params) {
    return _repository.getPurchases(
      fromDate: params.fromDate,
      toDate: params.toDate,
      paymentMode: params.paymentMode,
    );
  }
}

class GetPurchasesParams {
  const GetPurchasesParams({
    this.fromDate,
    this.toDate,
    this.paymentMode,
  });

  final DateTime? fromDate;
  final DateTime? toDate;
  final PaymentMode? paymentMode;
}
