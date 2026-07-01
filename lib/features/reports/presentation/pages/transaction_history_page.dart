import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/color_palette.dart';
import '../../../../shared/widgets/branding/developer_footer.dart';
import '../../../../shared/widgets/filters/register_date_filter_bar.dart';
import '../../../../shared/widgets/labels/bilingual_label.dart';
import '../../../../shared/widgets/feedback/app_error_view.dart';
import '../../../../shared/widgets/feedback/app_loading_view.dart';
import '../../data/datasources/transaction_history_local_datasource.dart';
import '../providers/history_providers.dart';
import '../utils/history_entry_navigation.dart';
import '../widgets/history_list_tile.dart';

/// Full register history — grouped by date, search, tap to edit.
class TransactionHistoryPage extends ConsumerStatefulWidget {
  const TransactionHistoryPage({super.key});

  @override
  ConsumerState<TransactionHistoryPage> createState() =>
      _TransactionHistoryPageState();
}

class _TransactionHistoryPageState extends ConsumerState<TransactionHistoryPage> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final groupedAsync = ref.watch(groupedTransactionHistoryProvider);
    final period = ref.watch(historyPeriodProvider);
    final customStart = ref.watch(historyCustomStartProvider);
    final customEnd = ref.watch(historyCustomEndProvider);

    return Scaffold(
      backgroundColor: ColorPalette.background,
      appBar: AppBar(
        backgroundColor: ColorPalette.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const BilingualLabel(
          english: 'Full Record',
          hindi: 'Poora Record',
          compact: true,
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  ref.read(historySearchQueryProvider.notifier).state = value;
                  setState(() {});
                },
                decoration: InputDecoration(
                  hintText: 'Party, type, rashi, tareekh…',
                  prefixIcon: const Icon(Icons.search_rounded, color: ColorPalette.purple),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_searchController.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20),
                          onPressed: () {
                            _searchController.clear();
                            ref.read(historySearchQueryProvider.notifier).state = '';
                            setState(() {});
                          },
                        ),
                      IconButton(
                        icon: const Icon(Icons.mic_none_rounded, size: 22),
                        onPressed: () {},
                        tooltip: 'Awaz se khojo (jald)',
                      ),
                    ],
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: RegisterDateFilterBar(
                period: period,
                customStart: customStart,
                customEnd: customEnd,
                onPeriodChanged: (value) {
                  ref.read(historyPeriodProvider.notifier).state = value;
                },
                onCustomRangeChanged: (start, end) {
                  ref.read(historyCustomStartProvider.notifier).state = start;
                  ref.read(historyCustomEndProvider.notifier).state = end;
                },
              ),
            ),
            Expanded(
              child: groupedAsync.when(
                loading: () => const AppLoadingView(),
                error: (error, _) => AppErrorView(
                  title: 'Record load nahi ho paya',
                  message: error.toString(),
                  actionLabel: 'Phir try karein',
                  onAction: () => ref.invalidate(transactionHistoryProvider),
                ),
                data: (sections) {
                  if (sections.isEmpty) {
                    return RefreshIndicator(
                      color: ColorPalette.purple,
                      onRefresh: () async => ref.invalidate(transactionHistoryProvider),
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                        children: [
                          SizedBox(height: MediaQuery.sizeOf(context).height * 0.14),
                          Center(
                            child: Text(
                              _searchController.text.trim().isEmpty
                                  ? 'Is samay koi entry nahi'
                                  : 'Match nahi mila — doosra shabd try karein',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Color(0xFF636366),
                              ),
                            ),
                          ),
                          const DeveloperFooter(),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    color: ColorPalette.purple,
                    onRefresh: () async => ref.invalidate(transactionHistoryProvider),
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                      itemCount: _listItemCount(sections),
                      itemBuilder: (context, index) {
                        if (index == _listItemCount(sections) - 1) {
                          return const DeveloperFooter();
                        }
                        return _buildListItem(context, sections, index);
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

  int _listItemCount(
    List<({String header, DateTime day, List<TransactionHistoryEntry> entries})>
        sections,
  ) {
    var count = 0;
    for (final section in sections) {
      count += 1 + section.entries.length;
    }
    return count + 1;
  }

  Widget _buildListItem(
    BuildContext context,
    List<({String header, DateTime day, List<TransactionHistoryEntry> entries})>
        sections,
    int index,
  ) {
    var cursor = 0;
    for (final section in sections) {
      if (cursor == index) {
        return Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 10),
          child: Text(
            section.header,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF636366),
            ),
          ),
        );
      }
      cursor++;

      for (final entry in section.entries) {
        if (cursor == index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: HistoryListTile(
              entry: entry,
              onTap: () => openHistoryEntry(context, entry),
            ),
          );
        }
        cursor++;
      }
    }
    return const SizedBox.shrink();
  }
}
