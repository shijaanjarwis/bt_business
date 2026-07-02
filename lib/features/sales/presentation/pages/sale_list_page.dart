import 'package:bt_business/core/errors/user_error_messages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../shared/widgets/branding/developer_footer.dart';
import '../../../../shared/widgets/buttons/app_register_fab.dart';
import '../../../../shared/widgets/chips/app_filter_chip.dart';
import '../../../../shared/widgets/feedback/app_error_view.dart';
import '../../../../shared/widgets/feedback/app_loading_view.dart';
import '../../../../shared/widgets/filters/register_date_filter_bar.dart';
import '../../../../shared/widgets/inputs/app_search_field.dart';
import '../../../../shared/widgets/register/register_entry_cards.dart';
import '../../../../shared/widgets/scaffold/app_register_app_bar.dart';
import '../../domain/entities/sale_entry.dart';
import '../models/sale_register_filter.dart';
import '../providers/sale_providers.dart';

/// Sales register — filter, search, tap for full details.
class SaleListPage extends ConsumerStatefulWidget {
  const SaleListPage({super.key});

  @override
  ConsumerState<SaleListPage> createState() => _SaleListPageState();
}

class _SaleListPageState extends ConsumerState<SaleListPage> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final salesAsync = ref.watch(saleListProvider);
    final registerFilter = ref.watch(saleRegisterFilterProvider);
    final datePeriod = ref.watch(saleRegisterDatePeriodProvider);
    final customStart = ref.watch(saleRegisterCustomStartProvider);
    final customEnd = ref.watch(saleRegisterCustomEndProvider);
    final cashCustomerId = ref.watch(cashCustomerPartyIdProvider).valueOrNull;

    return Scaffold(
      backgroundColor: ColorPalette.background,
      appBar: const AppRegisterAppBar(
        english: 'Sale',
        hindi: 'Bikri',
      ),
      floatingActionButton: AppRegisterFab(
        onPressed: () => context.push(RouteNames.salesNew),
        english: 'Sale',
        hindi: 'Bikri Likho',
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: AppSearchField(
                controller: _searchController,
                onChanged: (value) {
                  ref.read(saleSearchQueryProvider.notifier).state = value;
                },
                onClear: () {
                  _searchController.clear();
                  ref.read(saleSearchQueryProvider.notifier).state = '';
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: RegisterDateFilterBar(
                period: datePeriod,
                customStart: customStart,
                customEnd: customEnd,
                onPeriodChanged: (period) {
                  ref.read(saleRegisterDatePeriodProvider.notifier).state = period;
                },
                onCustomRangeChanged: (start, end) {
                  ref.read(saleRegisterCustomStartProvider.notifier).state = start;
                  ref.read(saleRegisterCustomEndProvider.notifier).state = end;
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    AppFilterChip(
                      label: 'All',
                      selected: registerFilter == SaleRegisterFilter.all,
                      onSelected: () => ref
                          .read(saleRegisterFilterProvider.notifier)
                          .state = SaleRegisterFilter.all,
                    ),
                    const SizedBox(width: 8),
                    AppFilterChip(
                      label: 'Cash',
                      selected: registerFilter == SaleRegisterFilter.todayCashReceived,
                      onSelected: () => ref
                          .read(saleRegisterFilterProvider.notifier)
                          .state = SaleRegisterFilter.todayCashReceived,
                    ),
                    const SizedBox(width: 8),
                    AppFilterChip(
                      label: 'Remaining',
                      selected: registerFilter == SaleRegisterFilter.hasBalance,
                      onSelected: () => ref
                          .read(saleRegisterFilterProvider.notifier)
                          .state = SaleRegisterFilter.hasBalance,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: salesAsync.when(
                loading: () => const AppLoadingView(),
                error: (error, _) => AppErrorView(
                  title: 'Register load nahi ho paya',
                  message: UserErrorMessages.from(error),
                  actionEnglish: 'Try Again',
                  actionHindi: 'Phir Try Karein',
                  onAction: () => ref.invalidate(saleListProvider),
                ),
                data: (sales) => _SaleRegisterList(
                  sales: sales,
                  cashCustomerPartyId: cashCustomerId,
                  onOpen: (entry) =>
                      context.push(RouteNames.salesDetailPath(entry.id)),
                  onRefresh: () async => ref.invalidate(saleListProvider),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SaleRegisterList extends StatelessWidget {
  const _SaleRegisterList({
    required this.sales,
    required this.onOpen,
    required this.onRefresh,
    this.cashCustomerPartyId,
  });

  final List<SaleEntry> sales;
  final String? cashCustomerPartyId;
  final ValueChanged<SaleEntry> onOpen;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    if (sales.isEmpty) {
      return RefreshIndicator(
        color: ColorPalette.purple,
        onRefresh: onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 96),
          children: [
            SizedBox(height: MediaQuery.sizeOf(context).height * 0.18),
            const Center(
              child: Text(
                'Pehli bikri likhein',
                style: TextStyle(
                  fontSize: 16,
                  color: ColorPalette.labelSecondary,
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
      onRefresh: onRefresh,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 96),
        itemCount: sales.length + 1,
        separatorBuilder: (context, index) {
          if (index >= sales.length - 1) return const SizedBox.shrink();
          return const SizedBox(height: 10);
        },
        itemBuilder: (context, index) {
          if (index == sales.length) return const DeveloperFooter();
          final entry = sales[index];
          return RegisterEntryCards.sale(
            entry: entry,
            cashCustomerPartyId: cashCustomerPartyId,
            onTap: () => onOpen(entry),
          );
        },
      ),
    );
  }
}
