import '../../../../core/errors/result.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/purchase_invoice.dart';
import '../repositories/purchase_repository.dart';

final class SearchPurchasesUseCase implements UseCase<List<PurchaseInvoice>, String> {
  const SearchPurchasesUseCase(this._repository);

  final PurchaseRepository _repository;

  @override
  Future<Result<List<PurchaseInvoice>>> call(String query) {
    return _repository.searchPurchases(query);
  }
}
