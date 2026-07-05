import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/data_revision.dart';
import '../../../../core/reminders/reminder_list_kind.dart';
import '../../../../core/reminders/reminder_models.dart';
import '../../../../core/reminders/reminder_providers.dart';
import '../../../../core/reminders/reminder_service.dart';

final reminderListSearchProvider =
    StateProvider.autoDispose.family<String, ReminderListKind>((ref, kind) => '');

final reminderListSubFilterProvider = StateProvider.autoDispose
    .family<ReminderListSubFilter, ReminderListKind>((ref, kind) {
  return ReminderListSubFilter.all;
});

Future<List<ReminderEntry>> _loadFilteredReminderEntries(
  Ref ref,
  ReminderListKind kind,
) async {
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
}

final filteredReminderListProvider =
    FutureProvider.autoDispose.family<List<ReminderEntry>, ReminderListKind>(
        (ref, kind) async {
  return _loadFilteredReminderEntries(ref, kind);
});

/// Pending receivable/payable list — one card per party.
final filteredPartyPendingGroupsProvider = FutureProvider.autoDispose
    .family<List<PartyPendingGroup>, ReminderListKind>((ref, kind) async {
  assert(kind.groupsByParty);
  final entries = await _loadFilteredReminderEntries(ref, kind);
  return ReminderService.groupByParty(entries);
});

typedef PartyPendingDetailArgs = ({ReminderListKind kind, String partyId});

/// All pending entries for one party on the detail screen (ignores list search).
final partyPendingDetailProvider = FutureProvider.autoDispose
    .family<List<ReminderEntry>, PartyPendingDetailArgs>((ref, args) async {
  ref.watch(dataRevisionProvider);
  final all = await ref.watch(reminderLocalDataSourceProvider).fetchActiveReminders();
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  return all
      .where(
        (entry) =>
            args.kind.matches(entry, today) && entry.partyId == args.partyId,
      )
      .toList()
    ..sort((a, b) => a.reminderDate.compareTo(b.reminderDate));
});
