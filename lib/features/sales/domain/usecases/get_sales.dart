import '../../../../core/accounting/payment_modes.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/sale_entry.dart';
import '../repositories/sale_repository.dart';

final class GetSalesUseCase implements UseCase<List<SaleEntry>, GetSalesParams> {
  const GetSalesUseCase(this._repository);

  final SaleRepository _repository;

  @override
  Future<Result<List<SaleEntry>>> call(GetSalesParams params) {
    return _repository.getSales(
      fromDate: params.fromDate,
      toDate: params.toDate,
      paymentMode: params.paymentMode,
      minDueAmount: params.minDueAmount,
      minPaidAmount: params.minPaidAmount,
    );
  }
}

class GetSalesParams {
  const GetSalesParams({
    this.fromDate,
    this.toDate,
    this.paymentMode,
    this.minDueAmount,
    this.minPaidAmount,
  });

  final DateTime? fromDate;
  final DateTime? toDate;
  final PaymentMode? paymentMode;
  final double? minDueAmount;
  final double? minPaidAmount;
}
