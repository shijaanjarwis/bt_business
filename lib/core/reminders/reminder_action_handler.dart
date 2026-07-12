import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../router/route_names.dart';
import 'reminder_action_payload.dart';
import 'reminder_models.dart';
import 'reminder_navigation.dart';
import 'reminder_notification_service.dart';
import 'reminder_scheduler.dart';
import 'reminder_snooze_store.dart';

/// Handles notification taps and action buttons — payment entry, snooze, open.
Future<void> handleReminderNotificationResponse({
  required NotificationResponse response,
  required void Function(String path) navigate,
  required ReminderSnoozeStore snoozeStore,
  required ReminderScheduler scheduler,
}) async {
  final actionId = response.actionId;
  final payload = response.payload;

  if (actionId != null && actionId.isNotEmpty) {
    final parsed = ReminderActionPayload.parse(payload);
    if (parsed != null) {
      switch (actionId) {
        case ReminderNotificationActions.snooze1h:
          await snoozeStore.snoozeUntil(
            parsed.transactionId,
            DateTime.now().add(const Duration(hours: 1)),
          );
          await scheduler.reschedule();
          return;
        case ReminderNotificationActions.snooze2h:
          await snoozeStore.snoozeUntil(
            parsed.transactionId,
            DateTime.now().add(const Duration(hours: 2)),
          );
          await scheduler.reschedule();
          return;
        case ReminderNotificationActions.snoozeTomorrow:
          final tomorrow = DateTime.now().add(const Duration(days: 1));
          await snoozeStore.snoozeUntil(
            parsed.transactionId,
            DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 8),
          );
          await scheduler.reschedule();
          return;
        case ReminderNotificationActions.receive:
          if (parsed.partyId.isNotEmpty) {
            navigate('${RouteNames.paymentsReceived}?partyId=${parsed.partyId}');
          }
          return;
        case ReminderNotificationActions.pay:
          if (parsed.partyId.isNotEmpty) {
            navigate('${RouteNames.paymentsPaid}?partyId=${parsed.partyId}');
          }
          return;
        case ReminderNotificationActions.open:
          final path = reminderDetailPathFromPayload(
            '${parsed.transactionType}:${parsed.transactionId}',
          );
          if (path != null) navigate(path);
          return;
      }
    }
  }

  handleReminderNotificationTap(payload: payload, navigate: navigate);
}

/// Android action buttons for a single reminder notification.
List<AndroidNotificationAction> reminderActionsForEntry(ReminderEntry entry) {
  final primary = entry.direction == ReminderDirection.receive
      ? const AndroidNotificationAction(
          ReminderNotificationActions.receive,
          'Paisa Mila',
          showsUserInterface: true,
          cancelNotification: true,
        )
      : const AndroidNotificationAction(
          ReminderNotificationActions.pay,
          'Paisa Diye',
          showsUserInterface: true,
          cancelNotification: true,
        );

  return [
    primary,
    const AndroidNotificationAction(
      ReminderNotificationActions.snooze1h,
      '1 Ghanta',
      cancelNotification: true,
    ),
    const AndroidNotificationAction(
      ReminderNotificationActions.open,
      'Kholiye',
      showsUserInterface: true,
      cancelNotification: true,
    ),
  ];
}

/// Grouped reminder notification — open list only.
List<AndroidNotificationAction> groupedReminderActions() {
  return const [
    AndroidNotificationAction(
      ReminderNotificationActions.open,
      'Kholiye',
      showsUserInterface: true,
      cancelNotification: true,
    ),
  ];
}
