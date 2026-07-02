import '../accounting/transaction_types.dart';

/// Receive money from party (sale udhaar / jama follow-up).
enum ReminderDirection {
  receive,
  payment;

  String get englishLabel => switch (this) {
        receive => 'Receive',
        payment => 'Payment',
      };

  String get hindiLabel => switch (this) {
        receive => 'Paisa Mile',
        payment => 'Paisa Diye',
      };

  static ReminderDirection fromTransactionType(String type) {
    return switch (type) {
      TransactionTypes.purchase => ReminderDirection.payment,
      TransactionTypes.paymentPaid => ReminderDirection.payment,
      _ => ReminderDirection.receive,
    };
  }
}

/// One pending reminder row for dashboard / notifications.
class ReminderEntry {
  const ReminderEntry({
    required this.transactionId,
    required this.transactionType,
    required this.partyId,
    required this.partyName,
    required this.amount,
    required this.reminderDate,
    required this.dueAmount,
    required this.direction,
  });

  final String transactionId;
  final String transactionType;
  final String partyId;
  final String partyName;
  final double amount;
  final DateTime reminderDate;
  final double dueAmount;
  final ReminderDirection direction;

  bool get isOverdue {
    final today = DateTime.now();
    final due = DateTime(reminderDate.year, reminderDate.month, reminderDate.day);
    final now = DateTime(today.year, today.month, today.day);
    return due.isBefore(now);
  }

  int get daysFromToday {
    final today = DateTime.now();
    final due = DateTime(reminderDate.year, reminderDate.month, reminderDate.day);
    final now = DateTime(today.year, today.month, today.day);
    return now.difference(due).inDays;
  }
}

/// Aggregated reminder counts and amounts for dashboard cards.
class ReminderDashboardSummary {
  const ReminderDashboardSummary({
    required this.receiveToday,
    required this.payToday,
    required this.pendingReceivable,
    required this.pendingPayable,
    required this.tomorrowReceive,
    required this.tomorrowPay,
    required this.next7DaysReceive,
    required this.next7DaysPay,
    required this.overdueReceive,
    required this.overduePay,
    required this.todayReminderCount,
  });

  final double receiveToday;
  final double payToday;
  final double pendingReceivable;
  final double pendingPayable;
  final double tomorrowReceive;
  final double tomorrowPay;
  final double next7DaysReceive;
  final double next7DaysPay;
  final double overdueReceive;
  final double overduePay;
  final int todayReminderCount;

  static const ReminderDashboardSummary zero = ReminderDashboardSummary(
    receiveToday: 0,
    payToday: 0,
    pendingReceivable: 0,
    pendingPayable: 0,
    tomorrowReceive: 0,
    tomorrowPay: 0,
    next7DaysReceive: 0,
    next7DaysPay: 0,
    overdueReceive: 0,
    overduePay: 0,
    todayReminderCount: 0,
  );

  bool get hasData =>
      receiveToday > 0 ||
      payToday > 0 ||
      pendingReceivable > 0 ||
      pendingPayable > 0 ||
      tomorrowReceive > 0 ||
      tomorrowPay > 0 ||
      next7DaysReceive > 0 ||
      next7DaysPay > 0 ||
      overdueReceive > 0 ||
      overduePay > 0;
}
