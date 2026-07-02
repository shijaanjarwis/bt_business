import '../../../../core/errors/result.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/register_list_filters.dart';
import '../entities/purchase_invoice.dart';
import '../repositories/purchase_repository.dart';

final class SearchPurchasesUseCase
    implements UseCase<List<PurchaseInvoice>, SearchRegisterParams> {
  const SearchPurchasesUseCase(this._repository);

  final PurchaseRepository _repository;

  @override
  Future<Result<List<PurchaseInvoice>>> call(SearchRegisterParams params) {
    final filters = params.filters;
    return _repository.searchPurchases(
      params.query,
      fromDate: filters.fromDate,
      toDate: filters.toDate,
      paymentMode: filters.paymentMode,
      minDueAmount: filters.minDueAmount,
      minPaidAmount: filters.minPaidAmount,
    );
  }
}
