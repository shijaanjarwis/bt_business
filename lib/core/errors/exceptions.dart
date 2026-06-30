/// Data-layer exceptions thrown before mapping to [Failure]s.
sealed class AppException implements Exception {
  const AppException(this.message);

  final String message;

  @override
  String toString() => message;
}

final class CacheException extends AppException {
  const CacheException(super.message);
}

final class DatabaseException extends AppException {
  const DatabaseException(super.message);
}

final class SyncException extends AppException {
  const SyncException(super.message);
}

final class ValidationException extends AppException {
  const ValidationException(super.message);
}
