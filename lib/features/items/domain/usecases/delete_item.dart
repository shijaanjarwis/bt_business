import '../../../../core/errors/result.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/item_repository.dart';

final class DeleteItemUseCase implements UseCase<void, String> {
  const DeleteItemUseCase(this._repository);

  final ItemRepository _repository;

  @override
  Future<Result<void>> call(String id) {
    return _repository.deleteItem(id);
  }
}
