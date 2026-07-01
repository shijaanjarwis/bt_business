import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../shared/widgets/branding/developer_footer.dart';
import '../../../../shared/widgets/feedback/app_error_view.dart';
import '../../../../shared/widgets/feedback/app_loading_view.dart';
import '../../../../shared/widgets/filters/register_date_filter_bar.dart';
import '../../../../shared/widgets/labels/bilingual_label.dart';
import '../../domain/entities/sale_entry.dart';
import '../models/sale_register_filter.dart';
import '../providers/sale_providers.dart';
import '../utils/sale_ui_helpers.dart';

/// Sales register — filter, search, tap to edit.
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
      appBar: AppBar(
        backgroundColor: ColorPalette.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const BilingualLabel(
          english: 'Sale Register',
          hindi: 'Bikri Register',
          compact: true,
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(RouteNames.salesNew),
        backgroundColor: ColorPalette.purple,
        icon: const Icon(Icons.edit_note_rounded),
        label: const BilingualLabel(
          english: 'Sell',
          hindi: 'Maal Becha',
          compact: true,
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  ref.read(saleSearchQueryProvider.notifier).state = value;
                },
                decoration: InputDecoration(
                  hintText: 'Party, maal, tareekh…',
                  prefixIcon: const Icon(Icons.search_rounded, color: ColorPalette.purple),
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
                    _FilterChip(
                      label: 'Sab',
                      selected: registerFilter == SaleRegisterFilter.all,
                      onSelected: () => ref
                          .read(saleRegisterFilterProvider.notifier)
                          .state = SaleRegisterFilter.all,
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Aaj Cash Mila',
                      selected: registerFilter == SaleRegisterFilter.todayCashReceived,
                      onSelected: () => ref
                          .read(saleRegisterFilterProvider.notifier)
                          .state = SaleRegisterFilter.todayCashReceived,
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Baaki',
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
                  message: error.toString(),
                  actionLabel: 'Phir try karein',
                  onAction: () => ref.invalidate(saleListProvider),
                ),
                data: (sales) {
                  if (sales.isEmpty) {
                    return RefreshIndicator(
                      color: ColorPalette.purple,
                      onRefresh: () async => ref.invalidate(saleListProvider),
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
                    onRefresh: () async => ref.invalidate(saleListProvider),
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 96),
                      itemCount: sales.length + 1,
                      separatorBuilder: (context, index) {
                        if (index >= sales.length - 1) {
                          return const SizedBox.shrink();
                        }
                        return const SizedBox(height: 10);
                      },
                      itemBuilder: (context, index) {
                        if (index == sales.length) {
                          return const DeveloperFooter();
                        }
                        final entry = sales[index];
                        return _SaleRegisterTile(
                          entry: entry,
                          cashCustomerPartyId: cashCustomerId,
                          onTap: () => context.push(RouteNames.salesEditPath(entry.id)),
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

class _SaleRegisterTile extends StatelessWidget {
  const _SaleRegisterTile({
    required this.entry,
    required this.onTap,
    this.cashCustomerPartyId,
  });

  final SaleEntry entry;
  final VoidCallback onTap;
  final String? cashCustomerPartyId;

  @override
  Widget build(BuildContext context) {
    final timeLabel = DateFormat('h:mm a').format(entry.createdAt);
    final partyLabel = SaleUiHelpers.partyLabel(
      partyId: entry.partyId,
      partyName: entry.partyName,
      cashCustomerPartyId: cashCustomerPartyId,
    );

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      partyLabel,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1C1C1E),
                      ),
                    ),
                  ),
                  Text(
                    CurrencyFormatter.format(entry.grandTotal),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: ColorPalette.purple,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _MetricChip(
                    label: 'Mila',
                    value: CurrencyFormatter.format(entry.paidAmount),
                    color: Colors.green.shade700,
                  ),
                  const SizedBox(width: 8),
                  _MetricChip(
                    label: 'Baaki',
                    value: CurrencyFormatter.format(entry.dueAmount),
                    color: entry.dueAmount > 0
                        ? Colors.orange.shade800
                        : ColorPalette.labelSecondary,
                  ),
                  const Spacer(),
                  Text(
                    '${DateFormatter.shortDate(entry.date)} · $timeLabel',
                    style: const TextStyle(
                      fontSize: 12,
                      color: ColorPalette.labelSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label $value',
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      selectedColor: ColorPalette.purple.withValues(alpha: 0.15),
      checkmarkColor: ColorPalette.purple,
    );
  }
}
