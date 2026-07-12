import 'reminder_models.dart';

/// Contract for scheduling and cancelling reminder notifications.
abstract interface class ReminderNotificationPort {
  Future<void> cancelReminderNotifications(String transactionId);

  Future<void> cancelGroupedReminders();

  Future<void> scheduleForReminder(
    ReminderEntry entry, {
    DateTime? reference,
  });

  Future<void> scheduleGroupedReminders({
    required List<ReminderEntry> entries,
    DateTime? reference,
  });
}
