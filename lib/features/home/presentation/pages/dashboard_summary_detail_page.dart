import 'package:bt_business/core/errors/user_error_messages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/color_palette.dart';
import '../../../../shared/widgets/branding/developer_footer.dart';
import '../../../../shared/widgets/feedback/app_error_view.dart';
import '../../../../shared/widgets/feedback/app_loading_view.dart';
import '../../../../shared/widgets/filters/register_date_filter_bar.dart';
import '../../../../shared/widgets/inputs/app_search_field.dart';
import '../../../../shared/widgets/scaffold/app_register_app_bar.dart';
import '../../../sales/presentation/providers/sale_providers.dart';
import '../models/dashboard_summary_kind.dart';
import '../providers/dashboard_summary_providers.dart';
import '../widgets/dashboard_summary_list_tile.dart';

/// Filtered register list opened from a dashboard summary card.
class DashboardSummaryDetailPage extends ConsumerStatefulWidget {
  const DashboardSummaryDetailPage({super.key, required this.kind});

  final DashboardSummaryKind kind;

  @override
  ConsumerState<DashboardSummaryDetailPage> createState() =>
      _DashboardSummaryDetailPageState();
}

class _DashboardSummaryDetailPageState
    extends ConsumerState<DashboardSummaryDetailPage> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _searchController.clear();
    ref.read(dashboardSummarySearchProvider(widget.kind).notifier).state = '';
  }

  void _invalidate() {
    ref.invalidate(dashboardSummarySalesProvider(widget.kind));
    ref.invalidate(dashboardSummaryPurchasesProvider(widget.kind));
    ref.invalidate(dashboardSummaryEntriesProvider(widget.kind));
  }

  @override
  Widget build(BuildContext context) {
    final kind = widget.kind;
    final datePeriod = ref.watch(dashboardSummaryDatePeriodProvider(kind));
    final customStart = ref.watch(dashboardSummaryCustomStartProvider(kind));
    final customEnd = ref.watch(dashboardSummaryCustomEndProvider(kind));

    return Scaffold(
      backgroundColor: ColorPalette.background,
      appBar: AppRegisterAppBar(
        english: kind.englishTitle,
        hindi: kind.hindiTitle,
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
                  ref.read(dashboardSummarySearchProvider(kind).notifier).state =
                      value;
                },
                onClear: _clearSearch,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: RegisterDateFilterBar(
                period: datePeriod,
                customStart: customStart,
                customEnd: customEnd,
                onPeriodChanged: (period) {
                  ref.read(dashboardSummaryDatePeriodProvider(kind).notifier).state =
                      period;
                },
                onCustomRangeChanged: (start, end) {
                  ref
                      .read(dashboardSummaryCustomStartProvider(kind).notifier)
                      .state = start;
                  ref.read(dashboardSummaryCustomEndProvider(kind).notifier).state =
                      end;
                },
              ),
            ),
            Expanded(
              child: switch (kind) {
                DashboardSummaryKind.todaySales ||
                DashboardSummaryKind.todayCredit =>
                  _SalesBody(kind: kind, onRetry: _invalidate),
                DashboardSummaryKind.todayPurchase =>
                  _PurchasesBody(kind: kind, onRetry: _invalidate),
                DashboardSummaryKind.todayCashReceived ||
                DashboardSummaryKind.cashInHand =>
                  _EntriesBody(kind: kind, onRetry: _invalidate),
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SalesBody extends ConsumerWidget {
  const _SalesBody({required this.kind, required this.onRetry});

  final DashboardSummaryKind kind;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salesAsync = ref.watch(dashboardSummarySalesProvider(kind));
    final cashCustomerId = ref.watch(cashCustomerPartyIdProvider).valueOrNull;

    return salesAsync.when(
      loading: () => const AppLoadingView(),
      error: (error, _) => AppErrorView(
        title: 'Entries load nahi ho payi',
        message: UserErrorMessages.from(error),
        actionEnglish: 'Try Again',
        actionHindi: 'Phir Try Karein',
        onAction: onRetry,
      ),
      data: (sales) => _SummaryList(
        isEmpty: sales.isEmpty,
        onRefresh: () async => onRetry(),
        itemCount: sales.length,
        itemBuilder: (index) => DashboardSummaryListTiles.sale(
          entry: sales[index],
          context: context,
          cashCustomerPartyId: cashCustomerId,
        ),
      ),
    );
  }
}

class _PurchasesBody extends ConsumerWidget {
  const _PurchasesBody({required this.kind, required this.onRetry});

  final DashboardSummaryKind kind;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final purchasesAsync = ref.watch(dashboardSummaryPurchasesProvider(kind));
    final cashCustomerId = ref.watch(cashCustomerPartyIdProvider).valueOrNull;

    return purchasesAsync.when(
      loading: () => const AppLoadingView(),
      error: (error, _) => AppErrorView(
        title: 'Entries load nahi ho payi',
        message: UserErrorMessages.from(error),
        actionEnglish: 'Try Again',
        actionHindi: 'Phir Try Karein',
        onAction: onRetry,
      ),
      data: (purchases) => _SummaryList(
        isEmpty: purchases.isEmpty,
        onRefresh: () async => onRetry(),
        itemCount: purchases.length,
        itemBuilder: (index) => DashboardSummaryListTiles.purchase(
          invoice: purchases[index],
          context: context,
          cashCustomerPartyId: cashCustomerId,
        ),
      ),
    );
  }
}

class _EntriesBody extends ConsumerWidget {
  const _EntriesBody({required this.kind, required this.onRetry});

  final DashboardSummaryKind kind;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(dashboardSummaryEntriesProvider(kind));

    return entriesAsync.when(
      loading: () => const AppLoadingView(),
      error: (error, _) => AppErrorView(
        title: 'Entries load nahi ho payi',
        message: UserErrorMessages.from(error),
        actionEnglish: 'Try Again',
        actionHindi: 'Phir Try Karein',
        onAction: onRetry,
      ),
      data: (entries) => _SummaryList(
        isEmpty: entries.isEmpty,
        onRefresh: () async => onRetry(),
        itemCount: entries.length,
        itemBuilder: (index) => DashboardSummaryListTiles.entry(
          entry: entries[index],
          context: context,
        ),
      ),
    );
  }
}

class _SummaryList extends StatelessWidget {
  const _SummaryList({
    required this.isEmpty,
    required this.onRefresh,
    required this.itemCount,
    required this.itemBuilder,
  });

  final bool isEmpty;
  final Future<void> Function() onRefresh;
  final int itemCount;
  final Widget Function(int index) itemBuilder;

  @override
  Widget build(BuildContext context) {
    if (isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        children: [
          SizedBox(height: MediaQuery.sizeOf(context).height * 0.18),
          const Center(
            child: Text(
              'No entries found.',
              textAlign: TextAlign.center,
              style: TextStyle(
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
      onRefresh: onRefresh,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        itemCount: itemCount + 1,
        separatorBuilder: (context, index) {
          if (index >= itemCount - 1) return const SizedBox.shrink();
          return const SizedBox(height: 10);
        },
        itemBuilder: (context, index) {
          if (index == itemCount) return const DeveloperFooter();
          return itemBuilder(index);
        },
      ),
    );
  }
}
