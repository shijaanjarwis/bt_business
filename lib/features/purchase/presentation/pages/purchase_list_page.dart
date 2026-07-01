import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../shared/widgets/branding/developer_footer.dart';
import '../../../../shared/widgets/filters/register_date_filter_bar.dart';
import '../../../../shared/widgets/labels/bilingual_label.dart';
import '../../../../shared/widgets/feedback/app_error_view.dart';
import '../../../../shared/widgets/feedback/app_loading_view.dart';
import '../../../sales/presentation/providers/sale_providers.dart';
import '../../domain/entities/purchase_invoice.dart';
import '../models/purchase_register_filter.dart';
import '../providers/purchase_providers.dart';
import '../utils/purchase_ui_helpers.dart';

/// Purchase register — same layout as Bikri Register.
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
      appBar: AppBar(
        backgroundColor: ColorPalette.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const BilingualLabel(
          english: 'Purchase Register',
          hindi: 'Kharid Register',
          compact: true,
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(RouteNames.purchasesNew),
        backgroundColor: ColorPalette.purple,
        icon: const Icon(Icons.edit_note_rounded),
        label: const BilingualLabel(
          english: 'Purchase',
          hindi: 'Maal Kharida',
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
                  ref.read(purchaseSearchQueryProvider.notifier).state = value;
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
                    _FilterChip(
                      label: 'Sab',
                      selected: registerFilter == PurchaseRegisterFilter.all,
                      onSelected: () => ref
                          .read(purchaseRegisterFilterProvider.notifier)
                          .state = PurchaseRegisterFilter.all,
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Aaj Diya',
                      selected: registerFilter == PurchaseRegisterFilter.todayPaid,
                      onSelected: () => ref
                          .read(purchaseRegisterFilterProvider.notifier)
                          .state = PurchaseRegisterFilter.todayPaid,
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Baaki',
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
                  message: error.toString(),
                  actionLabel: 'Phir try karein',
                  onAction: () => ref.invalidate(purchaseListProvider),
                ),
                data: (purchases) {
                  if (purchases.isEmpty) {
                    return RefreshIndicator(
                      color: ColorPalette.purple,
                      onRefresh: () async => ref.invalidate(purchaseListProvider),
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 96),
                        children: [
                          SizedBox(height: MediaQuery.sizeOf(context).height * 0.18),
                          const Center(
                            child: Text(
                              'Pehli kharid likhein',
                              style: TextStyle(
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
                    onRefresh: () async => ref.invalidate(purchaseListProvider),
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 96),
                      itemCount: purchases.length + 1,
                      separatorBuilder: (context, index) {
                        if (index >= purchases.length - 1) {
                          return const SizedBox.shrink();
                        }
                        return const SizedBox(height: 10);
                      },
                      itemBuilder: (context, index) {
                        if (index == purchases.length) {
                          return const DeveloperFooter();
                        }
                        final invoice = purchases[index];
                        return _PurchaseRegisterTile(
                          invoice: invoice,
                          defaultPartyId: defaultPartyId,
                          onTap: () =>
                              context.push(RouteNames.purchasesEditPath(invoice.id)),
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

class _PurchaseRegisterTile extends StatelessWidget {
  const _PurchaseRegisterTile({
    required this.invoice,
    required this.onTap,
    this.defaultPartyId,
  });

  final PurchaseInvoice invoice;
  final VoidCallback onTap;
  final String? defaultPartyId;

  @override
  Widget build(BuildContext context) {
    final timeLabel = DateFormat('h:mm a').format(invoice.createdAt);
    final partyLabel = PurchaseUiHelpers.partyLabel(
      partyId: invoice.partyId,
      partyName: invoice.partyName,
      defaultPartyId: defaultPartyId,
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
                    CurrencyFormatter.format(invoice.grandTotal),
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
                    label: 'Diya',
                    value: CurrencyFormatter.format(invoice.paidAmount),
                    color: Colors.green.shade700,
                  ),
                  const SizedBox(width: 8),
                  _MetricChip(
                    label: 'Baaki',
                    value: CurrencyFormatter.format(invoice.dueAmount),
                    color: invoice.dueAmount > 0
                        ? Colors.orange.shade800
                        : const Color(0xFF636366),
                  ),
                  const Spacer(),
                  Text(
                    '${DateFormatter.shortDate(invoice.date)} · $timeLabel',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF636366),
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
