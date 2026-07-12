import '../logging/logger.dart';
import '../../data/local/reminders/reminder_local_datasource.dart';
import 'reminder_models.dart';
import 'reminder_notification_port.dart';
import 'reminder_schedule_tracker.dart';
import 'reminder_snooze_store.dart';

/// Reconciles reminder notifications — grouped when multiple, per-reminder when one.
final class ReminderScheduler {
  ReminderScheduler(
    this._datasource,
    this._notifications,
    this._tracker,
    this._snoozeStore,
    this._logger,
  );

  final ReminderLocalDataSource _datasource;
  final ReminderNotificationPort _notifications;
  final ReminderScheduleTracker _tracker;
  final ReminderSnoozeStore _snoozeStore;
  final Logger _logger;

  /// Immediately cancels future notifications for a completed reminder.
  Future<void> cancelForTransaction(String transactionId) {
    return _notifications.cancelReminderNotifications(transactionId);
  }

  Future<void> reschedule({DateTime? reference}) async {
    try {
      final now = reference ?? DateTime.now();
      final due = await _datasource.fetchDueReminders(asOf: reference);
      final dueIds = due.map((entry) => entry.transactionId).toSet();
      final previouslyScheduled = await _tracker.loadScheduledTransactionIds();

      final completedIds = previouslyScheduled.difference(dueIds);
      for (final transactionId in completedIds) {
        await _notifications.cancelReminderNotifications(transactionId);
        await _snoozeStore.clear(transactionId);
        _logger.info('Payment completed — cancelled reminders for $transactionId');
      }

      await _notifications.cancelGroupedReminders();

      for (final transactionId in previouslyScheduled) {
        await _notifications.cancelReminderNotifications(transactionId);
      }

      final active = <ReminderEntry>[];
      for (final entry in due) {
        final snoozed = await _snoozeStore.isSnoozed(entry.transactionId, now);
        if (!snoozed) active.add(entry);
      }

      if (active.isEmpty) {
        await _tracker.saveScheduledTransactionIds({});
        return;
      }

      if (active.length == 1) {
        await _notifications.scheduleForReminder(active.first, reference: reference);
      } else {
        await _notifications.scheduleGroupedReminders(
          entries: active,
          reference: reference,
        );
      }

      await _tracker.saveScheduledTransactionIds(dueIds);
    } catch (error, stackTrace) {
      _logger.error('Reminder reschedule failed', error, stackTrace);
    }
  }
}
