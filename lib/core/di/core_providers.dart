import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../../data/local/database/app_database.dart';
import '../config/env.dart';
import '../logging/app_logger.dart';
import '../logging/logger.dart';

/// Global Riverpod providers for core services.
///
/// Feature-specific providers live under `lib/features/<feature>/`.
final loggerProvider = Provider<Logger>((ref) => const AppLogger());

final envProvider = Provider<AppEnvironment>((ref) => Env.environment);

/// Opens SQLite once at startup and keeps the connection alive.
final appDatabaseProvider = FutureProvider<Database>((ref) async {
  final link = ref.keepAlive();
  ref.onDispose(link.close);

  final logger = ref.read(loggerProvider);
  logger.info('Initializing database provider');

  return AppDatabase.open();
});
