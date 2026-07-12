import 'package:bt_business/core/reminders/reminder_models.dart';
import 'package:bt_business/core/reminders/reminder_notification_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReminderNotificationService IDs', () {
    test('uses distinct IDs for morning afternoon and evening', () {
      expect(ReminderNotificationService.morningNotificationId, 9001);
      expect(ReminderNotificationService.afternoonNotificationId, 9002);
      expect(ReminderNotificationService.eveningNotificationId, 9003);
      expect(
        ReminderNotificationService.morningNotificationId,
        isNot(ReminderNotificationService.afternoonNotificationId),
      );
      expect(
        ReminderNotificationService.afternoonNotificationId,
        isNot(ReminderNotificationService.eveningNotificationId),
      );
    });
  });

  group('ReminderNotificationContent', () {
    test('empty body means no notification', () {
      const content = ReminderNotificationContent(title: 'Test', body: '');
      expect(content.body.trim(), isEmpty);
    });
  });
}
