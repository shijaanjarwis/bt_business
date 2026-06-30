import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../features/sales/data/models/sale_item_model.dart';
import '../../data/datasources/purchase_local_datasource.dart';

final class SearchPurchaseItemsUseCase implements UseCase<List<SaleItem>, String> {
  const SearchPurchaseItemsUseCase(this._localDataSource);

  final PurchaseLocalDataSource _localDataSource;

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
