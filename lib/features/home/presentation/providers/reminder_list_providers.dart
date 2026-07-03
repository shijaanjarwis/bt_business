import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/data_revision.dart';
import '../../../../core/reminders/reminder_list_kind.dart';
import '../../../../core/reminders/reminder_models.dart';
import '../../../../core/reminders/reminder_providers.dart';

final reminderListSearchProvider =
    StateProvider.autoDispose.family<String, ReminderListKind>((ref, kind) => '');

final reminderListSubFilterProvider = StateProvider.autoDispose
    .family<ReminderListSubFilter, ReminderListKind>((ref, kind) {
  return ReminderListSubFilter.all;
});

final filteredReminderListProvider =
    FutureProvider.autoDispose.family<List<ReminderEntry>, ReminderListKind>(
        (ref, kind) async {
  ref.watch(dataRevisionProvider);
  final all = await ref.watch(reminderLocalDataSourceProvider).fetchActiveReminders();
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  var filtered = all.where((entry) => kind.matches(entry, today)).toList()
    ..sort((a, b) => a.reminderDate.compareTo(b.reminderDate));

  final search = ref.watch(reminderListSearchProvider(kind)).trim().toLowerCase();
  if (search.isNotEmpty) {
    filtered = filtered
        .where((entry) => entry.partyName.toLowerCase().contains(search))
        .toList();
  }

  if (kind.showsSubFilters) {
    final subFilter = ref.watch(reminderListSubFilterProvider(kind));
    filtered = switch (subFilter) {
      ReminderListSubFilter.all => filtered,
      ReminderListSubFilter.overdue =>
        filtered.where((entry) => entry.isOverdue).toList(),
      ReminderListSubFilter.thisWeek => filtered.where((entry) {
          final due = DateTime(
            entry.reminderDate.year,
            entry.reminderDate.month,
            entry.reminderDate.day,
          );
          final weekEnd = today.add(const Duration(days: 7));
          return !due.isBefore(today) && !due.isAfter(weekEnd);
        }).toList(),
    };
  }

  return filtered;
});
