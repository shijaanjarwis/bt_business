import '../../../../core/accounting/payment_modes.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/sale_invoice.dart';
import '../repositories/sale_repository.dart';

final class GetSalesUseCase implements UseCase<List<SaleInvoice>, GetSalesParams> {
  const GetSalesUseCase(this._repository);

  final SaleRepository _repository;

  @override
  Future<Result<List<SaleInvoice>>> call(GetSalesParams params) {
    return _repository.getSales(
      fromDate: params.fromDate,
      toDate: params.toDate,
      paymentMode: params.paymentMode,
    );
  }
}

class GetSalesParams {
  const GetSalesParams({
    this.fromDate,
    this.toDate,
    this.paymentMode,
  });

  final DateTime? fromDate;
  final DateTime? toDate;
  final PaymentMode? paymentMode;
}
