import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/usecases/usecase.dart';
import '../../data/datasources/sale_local_datasource.dart';
import '../../data/models/sale_item_model.dart';

final class SearchSaleItemsUseCase implements UseCase<List<SaleItem>, String> {
  const SearchSaleItemsUseCase(this._localDataSource);

  final SaleLocalDataSource _localDataSource;

  @override
  Future<Result<List<SaleItem>>> call(String query) async {
    try {
      final items = await _localDataSource.searchItems(query);
      return Success(items);
    } catch (error) {
      return Error(UnexpectedFailure(error.toString()));
    }
  }
}
