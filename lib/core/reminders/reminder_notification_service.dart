import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../logging/logger.dart';
import 'reminder_models.dart';
import 'reminder_navigation.dart';
import 'reminder_notification_ids.dart';
import 'reminder_notification_port.dart';
import 'reminder_service.dart';

/// Per-reminder 3-level notifications — cancel individually after payment.
final class ReminderNotificationService implements ReminderNotificationPort {
  ReminderNotificationService(this._logger);

  static const _channelId = 'bt_reminders';
  static const _channelName = 'Payment Reminders';

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

  /// Cancels all three slots for one reminder — other parties unaffected.
  @override
  Future<void> cancelReminderNotifications(String transactionId) async {
    if (!_supportsNotifications) return;

    final ids = ReminderNotificationIds.forTransaction(transactionId);
    await _plugin.cancel(ids.morning);
    await _plugin.cancel(ids.afternoon);
    await _plugin.cancel(ids.evening);
    _logger.info('Cancelled reminder notifications for $transactionId');
  }

  /// Removes legacy grouped notification IDs from the prior scheduler.
  @override
  Future<void> cancelLegacyGroupedReminders() async {
    if (!_supportsNotifications) return;
    await _plugin.cancel(LegacyReminderNotificationIds.morning);
    await _plugin.cancel(LegacyReminderNotificationIds.afternoon);
    await _plugin.cancel(LegacyReminderNotificationIds.evening);
  }

  /// Schedules morning / afternoon / evening for a single pending reminder.
  @override
  Future<void> scheduleForReminder(
    ReminderEntry entry, {
    DateTime? reference,
  }) async {
    if (!_supportsNotifications) return;

    await cancelReminderNotifications(entry.transactionId);

    final morning = ReminderService.buildNotificationContent(
      level: ReminderNotificationLevel.morning,
      dueTodayAndOverdue: [entry],
      reference: reference,
    );
    final afternoon = ReminderService.buildNotificationContent(
      level: ReminderNotificationLevel.afternoon,
      dueTodayAndOverdue: [entry],
      reference: reference,
    );
    final evening = ReminderService.buildNotificationContent(
      level: ReminderNotificationLevel.evening,
      dueTodayAndOverdue: [entry],
      reference: reference,
    );

    final ids = ReminderNotificationIds.forTransaction(entry.transactionId);
    final payload = ReminderService.notificationPayload(entry);
    final now = tz.TZDateTime.now(tz.local);

    if (morning.body.trim().isNotEmpty) {
      await _scheduleSlot(
        id: ids.morning,
        hour: 8,
        minute: 0,
        title: morning.title,
        body: morning.body,
        payload: payload,
        repeatDaily: true,
      );
    }

    if (_todayAt(13, 0).isAfter(now) && afternoon.body.trim().isNotEmpty) {
      await _scheduleSlot(
        id: ids.afternoon,
        hour: 13,
        minute: 0,
        title: afternoon.title,
        body: afternoon.body,
        payload: payload,
        repeatDaily: false,
      );
    }

    if (_todayAt(18, 0).isAfter(now) && evening.body.trim().isNotEmpty) {
      await _scheduleSlot(
        id: ids.evening,
        hour: 18,
        minute: 0,
        title: evening.title,
        body: evening.body,
        payload: payload,
        repeatDaily: false,
      );
    }
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
