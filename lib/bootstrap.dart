import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'app.dart';
import 'core/di/core_providers.dart';
import 'core/di/data_revision.dart';
import 'core/localization/localization_service.dart';
import 'core/logging/startup_trace.dart';
import 'core/reminders/reminder_notification_service.dart';
import 'core/reminders/reminder_providers.dart';
import 'core/router/app_router.dart';
import 'core/logging/logger.dart';

/// Initializes platform services and launches the application shell.
Future<void> bootstrap() async {
  StartupTrace.log('START bootstrap');
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isMacOS || Platform.isLinux || Platform.isWindows) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  tz_data.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));

  await LocalizationService.instance.ensureLoaded();

  final container = ProviderContainer();
  final logger = container.read(loggerProvider);

  FlutterError.onError = (details) {
    StartupTrace.log('FlutterError: ${details.exception}');
    logger.error(
      'Flutter framework error',
      details.exception,
      details.stack,
    );
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    StartupTrace.log('PlatformError: $error');
    logger.error('Uncaught async error', error, stack);
    return true;
  };

  ErrorWidget.builder = (details) {
    StartupTrace.log('ErrorWidget: ${details.exception}');
    return Material(
      color: const Color(0xFFF5F5F5),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            details.exceptionAsString(),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF333333), fontSize: 14),
          ),
        ),
      ),
    );
  };

  // Render UI immediately — never block first frame on database or notifications.
  StartupTrace.log('START runApp');
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const BtBusinessApp(),
    ),
  );
  StartupTrace.log('END runApp');

  WidgetsBinding.instance.addPostFrameCallback((_) {
    StartupTrace.log('START post-frame warmup');
    unawaited(_warmUpAppServices(container, logger));
  });
}

Future<void> _warmUpAppServices(ProviderContainer container, Logger logger) async {
  try {
    StartupTrace.log('START database');
    await container.read(appDatabaseProvider.future);
    StartupTrace.log('END database');
  } catch (error, stackTrace) {
    StartupTrace.log('FAIL database: $error');
    logger.error('Database warmup failed', error, stackTrace);
    return;
  }

  try {
    StartupTrace.log('START notifications');
    await _initializeReminders(container, logger);
    StartupTrace.log('END notifications');
    logger.info('Background services ready');
  } catch (error, stackTrace) {
    StartupTrace.log('FAIL notifications: $error');
    logger.error('Reminder init failed', error, stackTrace);
  }
}

Future<void> _initializeReminders(ProviderContainer container, Logger logger) async {
  final notifications = container.read(reminderNotificationServiceProvider);
  await notifications.initialize(
    onTap: (payload) {
      handleReminderNotificationTap(
        payload: payload,
        navigate: (path) {
          final context = rootNavigatorKey.currentContext;
          if (context != null && context.mounted) {
            GoRouter.of(context).push(path);
          }
        },
      );
    },
  );

  // iOS permission dialogs require an active UI window — never await before runApp.
  unawaited(
    notifications.requestPermissions().then((granted) {
      if (!granted) {
        container.read(notificationPermissionDeniedProvider.notifier).state = true;
      }
    }).timeout(
      const Duration(seconds: 15),
      onTimeout: () {
        StartupTrace.log('WARN notifications permission timed out');
        logger.warning('Notification permission request timed out');
      },
    ),
  );

  await container.read(reminderSchedulerProvider).reschedule();

  Timer? rescheduleTimer;
  container.listen<int>(dataRevisionProvider, (previous, next) {
    rescheduleTimer?.cancel();
    rescheduleTimer = Timer(const Duration(milliseconds: 100), () {
      container.read(reminderSchedulerProvider).reschedule();
    });
  });
}
