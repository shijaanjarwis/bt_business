/// Domain-layer failure types surfaced through [Result].
sealed class Failure {
  const Failure(this.message);

  final String message;
}

final class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

final class DatabaseFailure extends Failure {
  const DatabaseFailure(super.message);
}

final class SyncFailure extends Failure {
  const SyncFailure(super.message);
}

final class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

final class InitializationFailure extends Failure {
  const InitializationFailure(super.message);
}

final class UnexpectedFailure extends Failure {
  const UnexpectedFailure(super.message);
}
