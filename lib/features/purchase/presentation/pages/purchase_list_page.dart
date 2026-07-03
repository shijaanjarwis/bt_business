import 'package:bt_business/core/errors/user_error_messages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../shared/widgets/branding/developer_footer.dart';
import '../../../../shared/widgets/layout/main_shell_insets.dart';
import '../../../../shared/widgets/chips/app_filter_chip.dart';
import '../../../../shared/widgets/feedback/app_error_view.dart';
import '../../../../shared/widgets/feedback/app_loading_view.dart';
import '../../../../shared/widgets/filters/register_date_filter_bar.dart';
import '../../../../shared/widgets/inputs/app_search_field.dart';
import '../../../../shared/widgets/register/register_entry_cards.dart';
import '../../../../shared/widgets/scaffold/app_register_app_bar.dart';
import '../../../sales/presentation/providers/sale_providers.dart';
import '../../domain/entities/purchase_invoice.dart';
import '../models/purchase_register_filter.dart';
import '../providers/purchase_providers.dart';

/// Purchase register — same behaviour as sale register.
class PurchaseListPage extends ConsumerStatefulWidget {
  const PurchaseListPage({super.key});

  @override
  ConsumerState<PurchaseListPage> createState() => _PurchaseListPageState();
}

class _PurchaseListPageState extends ConsumerState<PurchaseListPage> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final purchasesAsync = ref.watch(purchaseListProvider);
    final registerFilter = ref.watch(purchaseRegisterFilterProvider);
    final datePeriod = ref.watch(purchaseRegisterDatePeriodProvider);
    final customStart = ref.watch(purchaseRegisterCustomStartProvider);
    final customEnd = ref.watch(purchaseRegisterCustomEndProvider);
    final defaultPartyId = ref.watch(cashCustomerPartyIdProvider).valueOrNull;

    return Scaffold(
      backgroundColor: ColorPalette.background,
      appBar: const AppRegisterAppBar(
        english: 'Purchase',
        hindi: 'Kharid',
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: AppSearchField(
                controller: _searchController,
                onChanged: (value) {
                  ref.read(purchaseSearchQueryProvider.notifier).state = value;
                },
                onClear: () {
                  _searchController.clear();
                  ref.read(purchaseSearchQueryProvider.notifier).state = '';
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
                  ref.read(purchaseRegisterDatePeriodProvider.notifier).state = period;
                },
                onCustomRangeChanged: (start, end) {
                  ref.read(purchaseRegisterCustomStartProvider.notifier).state = start;
                  ref.read(purchaseRegisterCustomEndProvider.notifier).state = end;
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
                      selected: registerFilter == PurchaseRegisterFilter.all,
                      onSelected: () => ref
                          .read(purchaseRegisterFilterProvider.notifier)
                          .state = PurchaseRegisterFilter.all,
                    ),
                    const SizedBox(width: 8),
                    AppFilterChip(
                      label: 'Paid',
                      selected: registerFilter == PurchaseRegisterFilter.todayPaid,
                      onSelected: () => ref
                          .read(purchaseRegisterFilterProvider.notifier)
                          .state = PurchaseRegisterFilter.todayPaid,
                    ),
                    const SizedBox(width: 8),
                    AppFilterChip(
                      label: 'Remaining',
                      selected: registerFilter == PurchaseRegisterFilter.hasBalance,
                      onSelected: () => ref
                          .read(purchaseRegisterFilterProvider.notifier)
                          .state = PurchaseRegisterFilter.hasBalance,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: purchasesAsync.when(
                loading: () => const AppLoadingView(),
                error: (error, _) => AppErrorView(
                  title: 'Register load nahi ho paya',
                  message: UserErrorMessages.from(error),
                  actionEnglish: 'Try Again',
                  actionHindi: 'Phir Try Karein',
                  onAction: () => ref.invalidate(purchaseListProvider),
                ),
                data: (purchases) => _PurchaseRegisterList(
                  purchases: purchases,
                  defaultPartyId: defaultPartyId,
                  onOpen: (invoice) =>
                      context.push(RouteNames.purchasesDetailPath(invoice.id)),
                  onRefresh: () async => ref.invalidate(purchaseListProvider),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PurchaseRegisterList extends StatelessWidget {
  const _PurchaseRegisterList({
    required this.purchases,
    required this.onOpen,
    required this.onRefresh,
    this.defaultPartyId,
  });

  final List<PurchaseInvoice> purchases;
  final String? defaultPartyId;
  final ValueChanged<PurchaseInvoice> onOpen;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    if (purchases.isEmpty) {
      return RefreshIndicator(
        color: ColorPalette.purple,
        onRefresh: onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: EdgeInsets.fromLTRB(
            20,
            0,
            20,
            MainShellInsets.scrollBottomWithFab(context),
          ),
          children: [
            SizedBox(height: MediaQuery.sizeOf(context).height * 0.18),
            const Center(
              child: Text(
                'Pehli kharid likhein',
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
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          MainShellInsets.scrollBottomWithFab(context),
        ),
        itemCount: purchases.length + 1,
        separatorBuilder: (context, index) {
          if (index >= purchases.length - 1) return const SizedBox.shrink();
          return const SizedBox(height: 10);
        },
        itemBuilder: (context, index) {
          if (index == purchases.length) return const DeveloperFooter();
          final invoice = purchases[index];
          return RegisterEntryCards.purchase(
            invoice: invoice,
            cashCustomerPartyId: defaultPartyId,
            onTap: () => onOpen(invoice),
          );
        },
      ),
    );
  }
}
