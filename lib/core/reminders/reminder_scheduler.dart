import '../logging/logger.dart';
import '../../data/local/reminders/reminder_local_datasource.dart';
import 'reminder_models.dart';
import 'reminder_notification_service.dart';
import 'reminder_service.dart';

/// Schedules 3-level reminders whenever data changes — cancels on payment.
final class ReminderScheduler {
  ReminderScheduler(
    this._datasource,
    this._notifications,
    this._logger,
  );

  final ReminderLocalDataSource _datasource;
  final ReminderNotificationService _notifications;
  final Logger _logger;

  Future<void> reschedule({DateTime? reference}) async {
    try {
      final due = await _datasource.fetchDueReminders(asOf: reference);

      if (due.isEmpty) {
        await _notifications.cancelAllReminders();
        return;
      }

      final morning = ReminderService.buildNotificationContent(
        level: ReminderNotificationLevel.morning,
        dueTodayAndOverdue: due,
        reference: reference,
      );
      final afternoon = ReminderService.buildNotificationContent(
        level: ReminderNotificationLevel.afternoon,
        dueTodayAndOverdue: due,
        reference: reference,
      );
      final evening = ReminderService.buildNotificationContent(
        level: ReminderNotificationLevel.evening,
        dueTodayAndOverdue: due,
        reference: reference,
      );

      await _notifications.scheduleThreeLevelReminders(
        morning: morning,
        afternoon: afternoon,
        evening: evening,
      );
    } catch (error, stackTrace) {
      _logger.error('Reminder reschedule failed', error, stackTrace);
    }
  }
}
