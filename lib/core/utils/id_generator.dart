import 'package:uuid/uuid.dart';

/// Generates offline-safe unique identifiers for persisted entities.
abstract final class IdGenerator {
  static const Uuid _uuid = Uuid();

  static String newId() => _uuid.v4();
}
