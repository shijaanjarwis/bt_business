/// Notification action IDs exposed on reminder alerts.
abstract final class ReminderNotificationActions {
  static const receive = 'receive';
  static const pay = 'pay';
  static const open = 'open';
  static const snooze1h = 'snooze_1h';
  static const snooze2h = 'snooze_2h';
  static const snoozeTomorrow = 'snooze_tomorrow';
}

/// Parses compact action payloads — `type:txId:partyId`.
class ReminderActionPayload {
  const ReminderActionPayload({
    required this.transactionType,
    required this.transactionId,
    required this.partyId,
  });

  final String transactionType;
  final String transactionId;
  final String partyId;

  static ReminderActionPayload? parse(String? payload) {
    if (payload == null || payload.isEmpty) return null;
    if (payload.startsWith('list:')) return null;

    final parts = payload.split(':');
    if (parts.length < 3) return null;

    return ReminderActionPayload(
      transactionType: parts[0],
      transactionId: parts[1],
      partyId: parts[2],
    );
  }

  String encode() => '$transactionType:$transactionId:$partyId';
}
