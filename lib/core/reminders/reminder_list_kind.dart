import 'reminder_models.dart';

/// Dashboard reminder card destinations.
enum ReminderListKind {
  receiveToday,
  payToday,
  pendingReceivable,
  pendingPayable,
  tomorrow,
  next7Days,
  overdue;

  static ReminderListKind? fromRoute(String slug) {
    return switch (slug) {
      'receive-today' => ReminderListKind.receiveToday,
      'pay-today' => ReminderListKind.payToday,
      'pending-receivable' => ReminderListKind.pendingReceivable,
      'pending-payable' => ReminderListKind.pendingPayable,
      'tomorrow' => ReminderListKind.tomorrow,
      'next-7-days' => ReminderListKind.next7Days,
      'overdue' => ReminderListKind.overdue,
      _ => null,
    };
  }

  String get routeSlug => switch (this) {
        ReminderListKind.receiveToday => 'receive-today',
        ReminderListKind.payToday => 'pay-today',
        ReminderListKind.pendingReceivable => 'pending-receivable',
        ReminderListKind.pendingPayable => 'pending-payable',
        ReminderListKind.tomorrow => 'tomorrow',
        ReminderListKind.next7Days => 'next-7-days',
        ReminderListKind.overdue => 'overdue',
      };

  String get englishTitle => switch (this) {
        ReminderListKind.receiveToday => 'Receive Today',
        ReminderListKind.payToday => 'Pay Today',
        ReminderListKind.pendingReceivable => 'Pending Receivable',
        ReminderListKind.pendingPayable => 'Pending Payable',
        ReminderListKind.tomorrow => 'Tomorrow',
        ReminderListKind.next7Days => 'Next 7 Days',
        ReminderListKind.overdue => 'Overdue',
      };

  String get hindiTitle => switch (this) {
        ReminderListKind.receiveToday => 'Aaj Lena Hai',
        ReminderListKind.payToday => 'Aaj Dena Hai',
        ReminderListKind.pendingReceivable => 'Lena Hai',
        ReminderListKind.pendingPayable => 'Dena Hai',
        ReminderListKind.tomorrow => 'Kal',
        ReminderListKind.next7Days => 'Agle 7 Din',
        ReminderListKind.overdue => 'Late Ho Gaya',
      };

  String get emptyMessage => switch (this) {
        ReminderListKind.receiveToday => 'No reminders for today.',
        ReminderListKind.payToday => 'No payment reminders for today.',
        ReminderListKind.pendingReceivable => 'No pending receivables.',
        ReminderListKind.pendingPayable => 'No pending payables.',
        ReminderListKind.tomorrow => 'No reminders for tomorrow.',
        ReminderListKind.next7Days => 'No reminders in the next 7 days.',
        ReminderListKind.overdue => 'No overdue reminders.',
      };

  bool get showsSubFilters =>
      this == ReminderListKind.pendingReceivable ||
      this == ReminderListKind.pendingPayable;

  bool matches(ReminderEntry entry, DateTime today) {
    final due = DateTime(
      entry.reminderDate.year,
      entry.reminderDate.month,
      entry.reminderDate.day,
    );
    final tomorrow = today.add(const Duration(days: 1));
    final weekEnd = today.add(const Duration(days: 7));
    final isReceive = entry.direction == ReminderDirection.receive;

    return switch (this) {
      ReminderListKind.receiveToday =>
        isReceive && due == today,
      ReminderListKind.payToday =>
        !isReceive && due == today,
      ReminderListKind.pendingReceivable => isReceive,
      ReminderListKind.pendingPayable => !isReceive,
      ReminderListKind.tomorrow =>
        due == tomorrow,
      ReminderListKind.next7Days =>
        due.isAfter(tomorrow) && !due.isAfter(weekEnd),
      ReminderListKind.overdue => due.isBefore(today),
    };
  }
}

enum ReminderListSubFilter { all, overdue, thisWeek }
