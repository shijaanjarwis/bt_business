import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/reminders/reminder_local_datasource.dart';
import '../di/core_providers.dart';
import '../di/data_revision.dart';
import 'reminder_models.dart';
import 'reminder_notification_service.dart';
import 'reminder_schedule_tracker.dart';
import 'reminder_scheduler.dart';
import 'reminder_service.dart';
import 'reminder_snooze_store.dart';

final reminderLocalDataSourceProvider = Provider<ReminderLocalDataSource>((ref) {
  final database = ref.watch(appDatabaseProvider).requireValue;
  return ReminderLocalDataSource(database);
});

class ReminderDashboardData {
  const ReminderDashboardData({
    required this.dueReminders,
    required this.summary,
  });

  final List<ReminderEntry> dueReminders;
  final ReminderDashboardSummary summary;
}

/// Single query pass for dashboard reminder list + summary cards.
final reminderDashboardProvider =
    FutureProvider.autoDispose<ReminderDashboardData>((ref) async {
  ref.watch(dataRevisionProvider);
  final datasource = ref.watch(reminderLocalDataSourceProvider);
  final active = await datasource.fetchActiveReminders();
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  final due = active.where((entry) {
    final dueDate = DateTime(
      entry.reminderDate.year,
      entry.reminderDate.month,
      entry.reminderDate.day,
    );
    return !dueDate.isAfter(today);
  }).toList();

  return ReminderDashboardData(
    dueReminders: due,
    summary: ReminderService.summarize(active, reference: now),
  );
});

/// Active reminders due today or overdue — for dashboard list.
final dashboardDueRemindersProvider = FutureProvider.autoDispose<List<ReminderEntry>>((ref) async {
  final data = await ref.watch(reminderDashboardProvider.future);
  return data.dueReminders;
});

/// Aggregated reminder amounts for dashboard cards.
final reminderSummaryProvider = FutureProvider.autoDispose<ReminderDashboardSummary>((ref) async {
  final data = await ref.watch(reminderDashboardProvider.future);
  return data.summary;
});

final reminderNotificationServiceProvider = Provider<ReminderNotificationService>((ref) {
  return ReminderNotificationService(ref.watch(loggerProvider));
});

final reminderScheduleTrackerProvider = Provider<ReminderScheduleTracker>((ref) {
  return ReminderScheduleTracker.create();
});

final reminderSnoozeStoreProvider = Provider<ReminderSnoozeStore>((ref) {
  return ReminderSnoozeStore.create();
});

final reminderSchedulerProvider = Provider<ReminderScheduler>((ref) {
  return ReminderScheduler(
    ref.watch(reminderLocalDataSourceProvider),
    ref.watch(reminderNotificationServiceProvider),
    ref.watch(reminderScheduleTrackerProvider),
    ref.watch(reminderSnoozeStoreProvider),
    ref.watch(loggerProvider),
  );
});

/// True when notification permission was denied — shows dashboard prompt.
final notificationPermissionDeniedProvider = StateProvider<bool>((ref) => false);
