import 'package:bt_business/core/errors/user_error_messages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../shared/widgets/branding/developer_footer.dart';
import '../../../../shared/widgets/buttons/app_register_fab.dart';
import '../../../../shared/widgets/chips/app_filter_chip.dart';
import '../../../../shared/widgets/filters/register_date_filter_bar.dart';
import '../../../../shared/widgets/inputs/app_search_field.dart';
import '../../../../shared/widgets/labels/bilingual_label.dart';
import '../../../../shared/widgets/scaffold/app_register_app_bar.dart';
import '../../../../shared/widgets/feedback/app_error_view.dart';
import '../../../../shared/widgets/feedback/app_loading_view.dart';
import '../models/payment_register_filter.dart';
import '../providers/payment_providers.dart';
import '../widgets/payment_list_tile.dart';

/// Jama / payment register — filter, search, tap to edit.
class PaymentRegisterPage extends ConsumerStatefulWidget {
  const PaymentRegisterPage({super.key});

  @override
  ConsumerState<PaymentRegisterPage> createState() => _PaymentRegisterPageState();
}

class _PaymentRegisterPageState extends ConsumerState<PaymentRegisterPage> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _searchController.clear();
    ref.read(paymentSearchQueryProvider.notifier).state = '';
  }

  @override
  Widget build(BuildContext context) {
    final paymentsAsync = ref.watch(paymentListProvider);
    final filter = ref.watch(paymentRegisterFilterProvider);
    final datePeriod = ref.watch(paymentRegisterDatePeriodProvider);
    final customStart = ref.watch(paymentRegisterCustomStartProvider);
    final customEnd = ref.watch(paymentRegisterCustomEndProvider);

    return Scaffold(
      backgroundColor: ColorPalette.background,
      appBar: const AppRegisterAppBar(
        english: 'Payment',
        hindi: 'Paise Diye',
      ),
      floatingActionButton: AppRegisterFab(
        onPressed: () => context.push(RouteNames.paymentsReceived),
        english: 'Receive',
        hindi: 'Paise Mile',
        icon: Icons.call_received_rounded,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: AppSearchField(
                controller: _searchController,
                onChanged: (value) {
                  ref.read(paymentSearchQueryProvider.notifier).state = value;
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
                  ref.read(paymentRegisterDatePeriodProvider.notifier).state = period;
                },
                onCustomRangeChanged: (start, end) {
                  ref.read(paymentRegisterCustomStartProvider.notifier).state = start;
                  ref.read(paymentRegisterCustomEndProvider.notifier).state = end;
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
                      selected: filter == PaymentRegisterFilter.all,
                      onSelected: () => ref
                          .read(paymentRegisterFilterProvider.notifier)
                          .state = PaymentRegisterFilter.all,
                    ),
                    const SizedBox(width: 8),
                    AppFilterChip(
                      label: 'Receive',
                      selected: filter == PaymentRegisterFilter.received,
                      onSelected: () => ref
                          .read(paymentRegisterFilterProvider.notifier)
                          .state = PaymentRegisterFilter.received,
                    ),
                    const SizedBox(width: 8),
                    AppFilterChip(
                      label: 'Payment',
                      selected: filter == PaymentRegisterFilter.paid,
                      onSelected: () => ref
                          .read(paymentRegisterFilterProvider.notifier)
                          .state = PaymentRegisterFilter.paid,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      english: 'Receive',
                      hindi: 'Paise Mile',
                      color: const Color(0xFF34C759),
                      onTap: () => context.push(RouteNames.paymentsReceived),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ActionButton(
                      english: 'Payment',
                      hindi: 'Paise Diye',
                      color: const Color(0xFFFF9500),
                      onTap: () => context.push(RouteNames.paymentsPaid),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: paymentsAsync.when(
                loading: () => const AppLoadingView(),
                error: (error, _) => AppErrorView(
                  title: 'Register load nahi ho paya',
                  message: UserErrorMessages.from(error),
                  actionEnglish: 'Try Again', actionHindi: 'Phir Try Karein',
                  onAction: () => ref.invalidate(paymentListProvider),
                ),
                data: (entries) {
                  if (entries.isEmpty) {
                    return RefreshIndicator(
                      color: ColorPalette.purple,
                      onRefresh: () async => ref.invalidate(paymentListProvider),
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 96),
                        children: [
                          SizedBox(height: MediaQuery.sizeOf(context).height * 0.14),
                          const Center(
                            child: Text(
                              'Pehla jama ya payment likhein',
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
                    onRefresh: () async => ref.invalidate(paymentListProvider),
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 96),
                      itemCount: entries.length + 1,
                      separatorBuilder: (context, index) {
                        if (index >= entries.length - 1) {
                          return const SizedBox.shrink();
                        }
                        return const SizedBox(height: 10);
                      },
                      itemBuilder: (context, index) {
                        if (index == entries.length) {
                          return Column(
                            children: [
                              TextButton(
                                onPressed: () => context.push(RouteNames.paymentsExpense),
                                child: const Text('Kharcha Likho'),
                              ),
                              const DeveloperFooter(),
                            ],
                          );
                        }
                        final entry = entries[index];
                        return PaymentListTile(
                          entry: entry,
                          onTap: () => context.push(RouteNames.paymentsDetailPath(entry.id)),
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

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.english,
    required this.hindi,
    required this.color,
    required this.onTap,
  });

  final String english;
  final String hindi;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Center(
            child: BilingualLabel(
              english: english,
              hindi: hindi,
              compact: true,
              crossAxisAlignment: CrossAxisAlignment.center,
              englishStyle: TextStyle(
                fontWeight: FontWeight.w700,
                color: color,
                fontSize: 14,
              ),
              hindiStyle: TextStyle(
                fontWeight: FontWeight.w500,
                color: color.withValues(alpha: 0.9),
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
