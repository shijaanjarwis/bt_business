import '../../../../core/errors/result.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/item.dart';
import '../repositories/item_repository.dart';

final class SearchItemsUseCase implements UseCase<List<Item>, String> {
  const SearchItemsUseCase(this._repository);

  final ItemRepository _repository;

  @override
  Future<Result<List<Item>>> call(String query) {
    return _repository.searchItems(query);
  }
}
