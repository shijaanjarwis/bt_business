import 'reminder_models.dart';

/// Contract for scheduling and cancelling per-reminder notifications.
abstract interface class ReminderNotificationPort {
  Future<void> cancelReminderNotifications(String transactionId);

  Future<void> cancelLegacyGroupedReminders();

  Future<void> scheduleForReminder(
    ReminderEntry entry, {
    DateTime? reference,
  });
}
