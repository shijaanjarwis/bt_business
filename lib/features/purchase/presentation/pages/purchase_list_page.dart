import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/accounting/payment_modes.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../shared/widgets/feedback/app_error_view.dart';
import '../../../../shared/widgets/feedback/app_loading_view.dart';
import '../../../../shared/widgets/labels/bilingual_label.dart';
import '../providers/purchase_providers.dart';
import '../widgets/purchase_list_tile.dart';

/// Purchase register — today's and past purchase entries.
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
    final paymentFilter = ref.watch(purchasePaymentFilterProvider);

    return Scaffold(
      backgroundColor: ColorPalette.background,
      appBar: AppBar(
        backgroundColor: ColorPalette.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const BilingualLabel(
          english: 'Purchase',
          hindi: 'Kharid ka register',
          compact: true,
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(RouteNames.purchasesNew),
        backgroundColor: ColorPalette.purple,
        icon: const Icon(Icons.edit_note_rounded),
        label: const Text('Record Purchase'),
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
                  hintText: 'Party, date…',
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
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'All · Sab',
                      selected: paymentFilter == null,
                      onSelected: () =>
                          ref.read(purchasePaymentFilterProvider.notifier).state = null,
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Abhi mila',
                      selected: paymentFilter == PaymentMode.cash,
                      onSelected: () => ref
                          .read(purchasePaymentFilterProvider.notifier)
                          .state = PaymentMode.cash,
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Udhaar',
                      selected: paymentFilter == PaymentMode.credit,
                      onSelected: () => ref
                          .read(purchasePaymentFilterProvider.notifier)
                          .state = PaymentMode.credit,
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
                  title: 'Purchases load nahi ho payi',
                  message: error.toString(),
                  actionLabel: 'Try Again',
                  onAction: () => ref.invalidate(purchaseListProvider),
                ),
                data: (purchases) {
                  if (purchases.isEmpty) {
                    return const Center(
                      child: BilingualLabel(
                        english: 'No purchases recorded yet',
                        hindi: 'Pehli kharid likho',
                      ),
                    );
                  }

                  return RefreshIndicator(
                    color: ColorPalette.purple,
                    onRefresh: () async => ref.invalidate(purchaseListProvider),
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 96),
                      itemCount: purchases.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final invoice = purchases[index];
                        return PurchaseListTile(
                          invoice: invoice,
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
