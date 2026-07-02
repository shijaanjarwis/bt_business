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
import 'bootstrap_error_app.dart';
import 'core/di/core_providers.dart';
import 'core/di/data_revision.dart';
import 'core/reminders/reminder_notification_service.dart';
import 'core/reminders/reminder_providers.dart';
import 'core/router/app_router.dart';
import 'core/logging/logger.dart';

/// Initializes platform services and launches the application shell.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isMacOS || Platform.isLinux || Platform.isWindows) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  tz_data.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));

  final container = ProviderContainer();
  final logger = container.read(loggerProvider);

  FlutterError.onError = (details) {
    logger.error(
      'Flutter framework error',
      details.exception,
      details.stack,
    );
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    logger.error('Uncaught async error', error, stack);
    return true;
  };

  try {
    await container.read(appDatabaseProvider.future);
    await _initializeReminders(container, logger);
    logger.info('Bootstrap complete');
  } catch (error, stackTrace) {
    logger.error('Bootstrap failed', error, stackTrace);
    runApp(BootstrapErrorApp(message: error.toString()));
    return;
  }

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const BtBusinessApp(),
    ),
  );
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
  await notifications.requestPermissions();
  await container.read(reminderSchedulerProvider).reschedule();

  Timer? rescheduleTimer;
  container.listen<int>(dataRevisionProvider, (previous, next) {
    rescheduleTimer?.cancel();
    rescheduleTimer = Timer(const Duration(milliseconds: 500), () {
      container.read(reminderSchedulerProvider).reschedule();
    });
  });
}
