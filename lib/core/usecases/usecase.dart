import '../errors/result.dart';

/// Base contract for domain use cases.
abstract interface class UseCase<T, Params> {
  Future<Result<T>> call(Params params);
}

/// Marker for use cases that require no parameters.
class NoParams {
  const NoParams();
}
