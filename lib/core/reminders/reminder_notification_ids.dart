/// Stable notification IDs per reminder transaction — morning, afternoon, evening.
class ReminderNotificationIds {
  const ReminderNotificationIds({
    required this.morning,
    required this.afternoon,
    required this.evening,
  });

  final int morning;
  final int afternoon;
  final int evening;

  static const int _base = 10000;
  static const int _slotSpan = 3;
  static const int _bucketCount = 290000;

  /// Derives three unique IDs from [transactionId] without colliding across slots.
  static ReminderNotificationIds forTransaction(String transactionId) {
    final bucket = _stableHash(transactionId) % _bucketCount;
    final start = _base + bucket * _slotSpan;
    return ReminderNotificationIds(
      morning: start,
      afternoon: start + 1,
      evening: start + 2,
    );
  }

  static int _stableHash(String value) {
    var hash = 0;
    for (final unit in value.codeUnits) {
      hash = 0x1fffffff & (hash + unit);
      hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
      hash ^= hash >> 6;
    }
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    hash ^= hash >> 11;
    return hash.abs();
  }
}

/// Legacy grouped notification IDs from earlier scheduler — cancelled on reconcile.
abstract final class LegacyReminderNotificationIds {
  static const morning = 9001;
  static const afternoon = 9002;
  static const evening = 9003;
}
