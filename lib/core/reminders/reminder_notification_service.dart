import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../logging/logger.dart';
import 'reminder_navigation.dart';

/// Single local notification engine — offline morning reminders at ~8 AM.
final class ReminderNotificationService {
  ReminderNotificationService(this._logger);

  static const _channelId = 'bt_reminders';
  static const _channelName = 'Payment Reminders';
  static const _morningNotificationId = 9001;

  final Logger _logger;
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  static Future<void> configureTimezone() async {
    tz.setLocalLocation(tz.local);
  }

  Future<void> initialize({
    void Function(String? payload)? onTap,
  }) async {
    if (_initialized) return;

    if (!_supportsNotifications) {
      _logger.info('Local notifications skipped on this platform');
      _initialized = true;
      return;
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: (response) {
        onTap?.call(response.payload);
      },
    );

    if (Platform.isAndroid) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              _channelId,
              _channelName,
              description: 'Daily payment and collection reminders',
              importance: Importance.high,
            ),
          );
    }

    _initialized = true;
    _logger.info('ReminderNotificationService initialized');
  }

  Future<void> requestPermissions() async {
    if (!_supportsNotifications) return;

    if (Platform.isAndroid) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }

    if (Platform.isIOS || Platform.isMacOS) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  Future<void> scheduleMorningReminder({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_supportsNotifications) return;

    await cancelMorningReminder();

    if (body.trim().isEmpty) return;

    final scheduled = _nextMorningEight();

    await _plugin.zonedSchedule(
      _morningNotificationId,
      title,
      body,
      scheduled,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.high,
          priority: Priority.high,
          styleInformation: BigTextStyleInformation(body),
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: payload,
    );
  }

  Future<void> cancelMorningReminder() async {
    if (!_supportsNotifications) return;
    await _plugin.cancel(_morningNotificationId);
  }

  tz.TZDateTime _nextMorningEight() {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, 8);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  bool get _supportsNotifications {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS;
  }
}

/// Handles notification tap navigation once the router is ready.
void handleReminderNotificationTap({
  required String? payload,
  required void Function(String path) navigate,
}) {
  final path = reminderDetailPathFromPayload(payload);
  if (path != null) navigate(path);
}
