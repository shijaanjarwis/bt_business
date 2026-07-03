import '../accounting/transaction_types.dart';
import '../utils/date_formatter.dart';
import 'reminder_models.dart';

/// Single source of truth for reminder business rules — offline, no duplicates.
abstract final class ReminderService {
  static bool isSaleOrPurchase(String type) {
    return type == TransactionTypes.sale || type == TransactionTypes.purchase;
  }

  /// Pending when sale/purchase has remaining balance, or payment has a reminder set.
  static bool isPending({
    required String transactionType,
    required double dueAmount,
    required DateTime? reminderDate,
  }) {
    if (isSaleOrPurchase(transactionType)) {
      return dueAmount > 0;
    }
    return reminderDate != null;
  }

  /// Clears reminder automatically when remaining is zero on sale/purchase.
  static DateTime? effectiveReminderDate({
    required String transactionType,
    required double dueAmount,
    required DateTime? requestedReminderDate,
  }) {
    if (requestedReminderDate == null) return null;
    if (isSaleOrPurchase(transactionType) && dueAmount <= 0) return null;
    return DateTime(
      requestedReminderDate.year,
      requestedReminderDate.month,
      requestedReminderDate.day,
    );
  }

  static String? reminderDateIso(DateTime? date) {
    if (date == null) return null;
    return DateFormatter.isoDate(date);
  }

  static DateTime? parseReminderDate(String? iso) {
    if (iso == null || iso.isEmpty) return null;
    return DateTime.parse(iso);
  }

  /// Amount shown on reminder cards — remaining for sale/purchase, full for payments.
  static double reminderAmount({
    required String transactionType,
    required double totalAmount,
    required double dueAmount,
  }) {
    if (isSaleOrPurchase(transactionType) && dueAmount > 0) {
      return dueAmount;
    }
    return totalAmount;
  }

  static int daysFromToday(DateTime reminderDate, {DateTime? reference}) {
    final ref = reference ?? DateTime.now();
    final due = DateTime(reminderDate.year, reminderDate.month, reminderDate.day);
    final today = DateTime(ref.year, ref.month, ref.day);
    return today.difference(due).inDays;
  }

  static String dueLabel(DateTime reminderDate, {DateTime? reference}) {
    final days = daysFromToday(reminderDate, reference: reference);
    if (days == 0) return 'Today';
    if (days == 1) return 'Overdue by 1 day';
    if (days > 1) return 'Overdue by $days days';
    if (days == -1) return 'Tomorrow';
    return 'In ${-days} days';
  }

  static ReminderEntry mapRow(Map<String, Object?> row) {
    final type = row['type']! as String;
    final total = (row['total_amount'] as num?)?.toDouble() ?? 0;
    final due = (row['due_amount'] as num?)?.toDouble() ?? 0;
    final reminderIso = row['reminder_date']! as String;

    return ReminderEntry(
      transactionId: row['id']! as String,
      transactionType: type,
      partyId: row['party_id']! as String,
      partyName: row['party_name']! as String,
      partyPhone: row['party_phone'] as String? ?? '',
      amount: reminderAmount(
        transactionType: type,
        totalAmount: total,
        dueAmount: due,
      ),
      reminderDate: DateTime.parse(reminderIso),
      dueAmount: due,
      direction: ReminderDirection.fromTransactionType(type),
    );
  }

  static ReminderDashboardSummary summarize(List<ReminderEntry> entries, {DateTime? reference}) {
    final ref = reference ?? DateTime.now();
    final today = DateTime(ref.year, ref.month, ref.day);
    final tomorrow = today.add(const Duration(days: 1));
    final weekEnd = today.add(const Duration(days: 7));

    double receiveToday = 0;
    double payToday = 0;
    double pendingReceivable = 0;
    double pendingPayable = 0;
    double tomorrowReceive = 0;
    double tomorrowPay = 0;
    double next7Receive = 0;
    double next7Pay = 0;
    double overdueReceive = 0;
    double overduePay = 0;
    var todayCount = 0;

    for (final entry in entries) {
      final due = DateTime(
        entry.reminderDate.year,
        entry.reminderDate.month,
        entry.reminderDate.day,
      );
      final isReceive = entry.direction == ReminderDirection.receive;

      if (isReceive) {
        pendingReceivable += entry.amount;
      } else {
        pendingPayable += entry.amount;
      }

      if (due.isBefore(today)) {
        if (isReceive) {
          overdueReceive += entry.amount;
        } else {
          overduePay += entry.amount;
        }
        todayCount++;
      } else if (due == today) {
        if (isReceive) {
          receiveToday += entry.amount;
        } else {
          payToday += entry.amount;
        }
        todayCount++;
      } else if (due == tomorrow) {
        if (isReceive) {
          tomorrowReceive += entry.amount;
        } else {
          tomorrowPay += entry.amount;
        }
      } else if (due.isAfter(tomorrow) && !due.isAfter(weekEnd)) {
        if (isReceive) {
          next7Receive += entry.amount;
        } else {
          next7Pay += entry.amount;
        }
      }
    }

    return ReminderDashboardSummary(
      receiveToday: receiveToday,
      payToday: payToday,
      pendingReceivable: pendingReceivable,
      pendingPayable: pendingPayable,
      tomorrowReceive: tomorrowReceive,
      tomorrowPay: tomorrowPay,
      next7DaysReceive: next7Receive,
      next7DaysPay: next7Pay,
      overdueReceive: overdueReceive,
      overduePay: overduePay,
      todayReminderCount: todayCount,
    );
  }

  /// Builds a concise morning notification body — combines when possible.
  static String buildMorningNotificationBody({
    required List<ReminderEntry> dueTodayAndOverdue,
    required ReminderDashboardSummary summary,
    DateTime? reference,
  }) {
    if (dueTodayAndOverdue.isEmpty) {
      return 'No pending reminders today.';
    }

    final parts = <String>[];
    final sorted = [...dueTodayAndOverdue]
      ..sort((a, b) {
        final aDays = daysFromToday(a.reminderDate, reference: reference);
        final bDays = daysFromToday(b.reminderDate, reference: reference);
        if (aDays != bDays) return bDays.compareTo(aDays);
        return a.reminderDate.compareTo(b.reminderDate);
      });

    for (final entry in sorted.take(2)) {
      final preposition =
          entry.direction == ReminderDirection.receive ? 'from' : 'to';
      final days = daysFromToday(entry.reminderDate, reference: reference);
      final prefix = days > 0 ? 'Overdue' : 'Today';
      parts.add(
        '$prefix ${entry.direction.englishLabel.toLowerCase()} '
        '₹${_format(entry.amount)} $preposition ${entry.partyName}',
      );
    }

    if (dueTodayAndOverdue.length > 2) {
      parts.add(
        'You have ${dueTodayAndOverdue.length} pending reminders today.',
      );
    } else if (dueTodayAndOverdue.length > 1 && parts.length == 1) {
      parts.add(
        'You have ${dueTodayAndOverdue.length} pending reminders today.',
      );
    }

    return parts.join('. ');
  }

  /// Payload for notification tap — `transactionType:transactionId`.
  static String notificationPayload(ReminderEntry entry) {
    return '${entry.transactionType}:${entry.transactionId}';
  }

  static String _format(double value) {
    if (value == value.roundToDouble()) {
      return value.round().toString();
    }
    return value.toStringAsFixed(0);
  }
}
