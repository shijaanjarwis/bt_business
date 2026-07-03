import 'package:bt_business/core/errors/user_error_messages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/reminders/reminder_list_kind.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../shared/widgets/branding/developer_footer.dart';
import '../../../../shared/widgets/chips/app_filter_chip.dart';
import '../../../../shared/widgets/feedback/app_error_view.dart';
import '../../../../shared/widgets/feedback/app_loading_view.dart';
import '../../../../shared/widgets/inputs/app_search_field.dart';
import '../../../../shared/widgets/scaffold/app_register_app_bar.dart';
import '../../../ledger/presentation/providers/party_ledger_extras_provider.dart';
import '../providers/reminder_list_providers.dart';
import '../widgets/reminder_list_tile.dart';

/// Full-screen reminder list opened from dashboard summary cards.
class ReminderListPage extends ConsumerStatefulWidget {
  const ReminderListPage({super.key, required this.kind});

  final ReminderListKind kind;

  @override
  ConsumerState<ReminderListPage> createState() => _ReminderListPageState();
}

class _ReminderListPageState extends ConsumerState<ReminderListPage> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _searchController.clear();
    ref.read(reminderListSearchProvider(widget.kind).notifier).state = '';
  }

  @override
  Widget build(BuildContext context) {
    final entriesAsync = ref.watch(filteredReminderListProvider(widget.kind));
    final lastActivityMap =
        ref.watch(partyLastActivityProvider).valueOrNull ?? {};
    final subFilter = ref.watch(reminderListSubFilterProvider(widget.kind));
    final showLastActivity = widget.kind == ReminderListKind.pendingReceivable ||
        widget.kind == ReminderListKind.pendingPayable;

    return Scaffold(
      backgroundColor: ColorPalette.background,
      appBar: AppRegisterAppBar(
        english: widget.kind.englishTitle,
        hindi: widget.kind.hindiTitle,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: AppSearchField(
                controller: _searchController,
                onChanged: (value) {
                  ref.read(reminderListSearchProvider(widget.kind).notifier).state =
                      value;
                },
                onClear: _clearSearch,
              ),
            ),
            if (widget.kind.showsSubFilters)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      AppFilterChip(
                        label: 'All',
                        selected: subFilter == ReminderListSubFilter.all,
                        onSelected: () => ref
                            .read(reminderListSubFilterProvider(widget.kind).notifier)
                            .state = ReminderListSubFilter.all,
                      ),
                      const SizedBox(width: 8),
                      AppFilterChip(
                        label: 'Overdue',
                        selected: subFilter == ReminderListSubFilter.overdue,
                        onSelected: () => ref
                            .read(reminderListSubFilterProvider(widget.kind).notifier)
                            .state = ReminderListSubFilter.overdue,
                      ),
                      const SizedBox(width: 8),
                      AppFilterChip(
                        label: 'This Week',
                        selected: subFilter == ReminderListSubFilter.thisWeek,
                        onSelected: () => ref
                            .read(reminderListSubFilterProvider(widget.kind).notifier)
                            .state = ReminderListSubFilter.thisWeek,
                      ),
                    ],
                  ),
                ),
              ),
            Expanded(
              child: entriesAsync.when(
                loading: () => const AppLoadingView(),
                error: (error, _) => AppErrorView(
                  title: 'Reminder load nahi ho paya',
                  message: UserErrorMessages.from(error),
                  actionEnglish: 'Try Again',
                  actionHindi: 'Phir Try Karein',
                  onAction: () =>
                      ref.invalidate(filteredReminderListProvider(widget.kind)),
                ),
                data: (entries) {
                  if (entries.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                      children: [
                        SizedBox(height: MediaQuery.sizeOf(context).height * 0.18),
                        Center(
                          child: Text(
                            widget.kind.emptyMessage,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              color: ColorPalette.labelSecondary,
                            ),
                          ),
                        ),
                        const DeveloperFooter(),
                      ],
                    );
                  }

                  return RefreshIndicator(
                    color: ColorPalette.purple,
                    onRefresh: () async {
                      ref.invalidate(filteredReminderListProvider(widget.kind));
                      ref.invalidate(partyLastActivityProvider);
                    },
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                      itemCount: entries.length + 1,
                      separatorBuilder: (context, index) {
                        if (index >= entries.length - 1) {
                          return const SizedBox.shrink();
                        }
                        return const SizedBox(height: 10);
                      },
                      itemBuilder: (context, index) {
                        if (index == entries.length) {
                          return const DeveloperFooter();
                        }
                        final entry = entries[index];
                        return ReminderListTile(
                          entry: entry,
                          showLastActivity: showLastActivity,
                          lastActivity: lastActivityMap[entry.partyId],
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
