import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../logging/logger.dart';
import 'reminder_models.dart';
import 'reminder_navigation.dart';

/// Three-level local notification engine — 8 AM, 1 PM, 6 PM offline reminders.
final class ReminderNotificationService {
  ReminderNotificationService(this._logger);

  static const _channelId = 'bt_reminders';
  static const _channelName = 'Payment Reminders';
  static const morningNotificationId = 9001;
  static const afternoonNotificationId = 9002;
  static const eveningNotificationId = 9003;

  final Logger _logger;
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool? _lastPermissionGranted;

  bool get lastPermissionGranted => _lastPermissionGranted ?? false;

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

  Future<bool> requestPermissions() async {
    if (!_supportsNotifications) {
      _lastPermissionGranted = false;
      return false;
    }

    var granted = true;

    if (Platform.isAndroid) {
      granted = await _plugin
              .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>()
              ?.requestNotificationsPermission() ??
          true;
    }

    if (Platform.isIOS || Platform.isMacOS) {
      granted = await _plugin
              .resolvePlatformSpecificImplementation<
                  IOSFlutterLocalNotificationsPlugin>()
              ?.requestPermissions(alert: true, badge: true, sound: true) ??
          false;
    }

    _lastPermissionGranted = granted;
    return granted;
  }

  /// Schedules morning (repeating), afternoon, and evening slots for today.
  Future<void> scheduleThreeLevelReminders({
    required ReminderNotificationContent morning,
    required ReminderNotificationContent afternoon,
    required ReminderNotificationContent evening,
  }) async {
    if (!_supportsNotifications) return;

    await cancelAllReminders();

    if (morning.body.trim().isEmpty) return;

    await _scheduleSlot(
      id: morningNotificationId,
      hour: 8,
      minute: 0,
      title: morning.title,
      body: morning.body,
      payload: morning.payload,
      repeatDaily: true,
    );

    final now = tz.TZDateTime.now(tz.local);
    final afternoonTime = _todayAt(13, 0);
    if (afternoonTime.isAfter(now) && afternoon.body.trim().isNotEmpty) {
      await _scheduleSlot(
        id: afternoonNotificationId,
        hour: 13,
        minute: 0,
        title: afternoon.title,
        body: afternoon.body,
        payload: afternoon.payload,
        repeatDaily: false,
      );
    }

    final eveningTime = _todayAt(18, 0);
    if (eveningTime.isAfter(now) && evening.body.trim().isNotEmpty) {
      await _scheduleSlot(
        id: eveningNotificationId,
        hour: 18,
        minute: 0,
        title: evening.title,
        body: evening.body,
        payload: evening.payload,
        repeatDaily: false,
      );
    }
  }

  Future<void> cancelAllReminders() async {
    if (!_supportsNotifications) return;
    await _plugin.cancel(morningNotificationId);
    await _plugin.cancel(afternoonNotificationId);
    await _plugin.cancel(eveningNotificationId);
  }

  @Deprecated('Use cancelAllReminders')
  Future<void> cancelMorningReminder() => cancelAllReminders();

  @Deprecated('Use scheduleThreeLevelReminders')
  Future<void> scheduleMorningReminder({
    required String title,
    required String body,
    String? payload,
  }) {
    return scheduleThreeLevelReminders(
      morning: ReminderNotificationContent(title: title, body: body, payload: payload),
      afternoon: const ReminderNotificationContent(title: '', body: ''),
      evening: const ReminderNotificationContent(title: '', body: ''),
    );
  }

  Future<void> _scheduleSlot({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
    String? payload,
    required bool repeatDaily,
  }) async {
    var scheduled = _todayAt(hour, minute);
    final now = tz.TZDateTime.now(tz.local);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id,
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
      matchDateTimeComponents:
          repeatDaily ? DateTimeComponents.time : null,
      payload: payload,
    );
  }

  tz.TZDateTime _todayAt(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    return tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
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
  final path = reminderNavigationPathFromPayload(payload);
  if (path != null) navigate(path);
}
