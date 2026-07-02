import '../../../../core/errors/result.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/sale_entry.dart';
import '../../../../core/utils/register_list_filters.dart';
import '../repositories/sale_repository.dart';

final class SearchSalesUseCase
    implements UseCase<List<SaleEntry>, SearchRegisterParams> {
  const SearchSalesUseCase(this._repository);

  final SaleRepository _repository;

  @override
  Future<Result<List<SaleEntry>>> call(SearchRegisterParams params) {
    final filters = params.filters;
    return _repository.searchSales(
      params.query,
      fromDate: filters.fromDate,
      toDate: filters.toDate,
      paymentMode: filters.paymentMode,
      minDueAmount: filters.minDueAmount,
      minPaidAmount: filters.minPaidAmount,
    );
  }
}
