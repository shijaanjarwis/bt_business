import '../logging/logger.dart';
import '../../data/local/reminders/reminder_local_datasource.dart';
import 'reminder_models.dart';
import 'reminder_notification_service.dart';
import 'reminder_service.dart';

/// Single scheduler — refreshes the morning reminder whenever data changes.
final class ReminderScheduler {
  ReminderScheduler(
    this._datasource,
    this._notifications,
    this._logger,
  );

  final ReminderLocalDataSource _datasource;
  final ReminderNotificationService _notifications;
  final Logger _logger;

  static const _title = 'BT Business Reminders';

  Future<void> reschedule({DateTime? reference}) async {
    try {
      final due = await _datasource.fetchDueReminders(asOf: reference);
      final summary = await _datasource.fetchSummary(asOf: reference);

      if (due.isEmpty) {
        await _notifications.cancelMorningReminder();
        return;
      }

      final body = ReminderService.buildMorningNotificationBody(
        dueTodayAndOverdue: due,
        summary: summary,
        reference: reference,
      );

      final payloadEntry = _primaryPayloadEntry(due);
      final payload = payloadEntry == null
          ? null
          : ReminderService.notificationPayload(payloadEntry);

      await _notifications.scheduleMorningReminder(
        title: _title,
        body: body,
        payload: payload,
      );
    } catch (error, stackTrace) {
      _logger.error('Reminder reschedule failed', error, stackTrace);
    }
  }

  ReminderEntry? _primaryPayloadEntry(List<ReminderEntry> due) {
    if (due.isEmpty) return null;

    final sorted = [...due]
      ..sort((a, b) {
        if (a.isOverdue != b.isOverdue) return a.isOverdue ? -1 : 1;
        return a.reminderDate.compareTo(b.reminderDate);
      });
    return sorted.first;
  }
}
