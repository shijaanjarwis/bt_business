import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'app.dart';
import 'bootstrap_error_app.dart';
import 'core/di/core_providers.dart';

/// Initializes platform services and launches the application shell.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isMacOS || Platform.isLinux || Platform.isWindows) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

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
