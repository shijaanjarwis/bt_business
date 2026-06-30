import 'exceptions.dart';
import 'failures.dart';

/// Maps data-layer exceptions to domain [Failure] types.
abstract final class ExceptionMapper {
  static Failure map(Object error, [StackTrace? stackTrace]) {
    if (error is Failure) return error;

    return switch (error) {
      ValidationException(message: final m) => ValidationFailure(m),
      DatabaseException(message: final m) => DatabaseFailure(m),
      CacheException(message: final m) => CacheFailure(m),
      SyncException(message: final m) => SyncFailure(m),
      _ => UnexpectedFailure(
          error is Exception ? error.toString() : 'An unexpected error occurred',
        ),
    };
  }
}
