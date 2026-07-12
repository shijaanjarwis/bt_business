import '../logging/logger.dart';
import '../../data/local/reminders/reminder_local_datasource.dart';
import 'reminder_notification_port.dart';
import 'reminder_schedule_tracker.dart';

/// Reconciles per-reminder notifications — cancels completed, updates partial.
final class ReminderScheduler {
  ReminderScheduler(
    this._datasource,
    this._notifications,
    this._tracker,
    this._logger,
  );

  final ReminderLocalDataSource _datasource;
  final ReminderNotificationPort _notifications;
  final ReminderScheduleTracker _tracker;
  final Logger _logger;

  /// Immediately cancels future notifications for a completed reminder.
  Future<void> cancelForTransaction(String transactionId) {
    return _notifications.cancelReminderNotifications(transactionId);
  }

  Future<void> reschedule({DateTime? reference}) async {
    try {
      final due = await _datasource.fetchDueReminders(asOf: reference);
      final dueIds = due.map((entry) => entry.transactionId).toSet();
      final previouslyScheduled = await _tracker.loadScheduledTransactionIds();

      final completedIds = previouslyScheduled.difference(dueIds);
      for (final transactionId in completedIds) {
        await _notifications.cancelReminderNotifications(transactionId);
        _logger.info('Payment completed — cancelled reminders for $transactionId');
      }

      await _notifications.cancelLegacyGroupedReminders();

      if (due.isEmpty) {
        await _tracker.saveScheduledTransactionIds({});
        return;
      }

      for (final entry in due) {
        await _notifications.scheduleForReminder(entry, reference: reference);
      }

      await _tracker.saveScheduledTransactionIds(dueIds);
    } catch (error, stackTrace) {
      _logger.error('Reminder reschedule failed', error, stackTrace);
    }
  }
}
