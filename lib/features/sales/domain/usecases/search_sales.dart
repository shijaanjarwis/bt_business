import '../../../../core/errors/result.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/sale_entry.dart';
import '../repositories/sale_repository.dart';

final class SearchSalesUseCase implements UseCase<List<SaleEntry>, String> {
  const SearchSalesUseCase(this._repository);

  final SaleRepository _repository;

  @override
  Future<Result<List<SaleEntry>>> call(String query) {
    return _repository.searchSales(query);
  }
}
