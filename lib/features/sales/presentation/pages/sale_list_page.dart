import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/accounting/payment_modes.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../shared/widgets/feedback/app_error_view.dart';
import '../../../../shared/widgets/feedback/app_loading_view.dart';
import '../../../../shared/widgets/labels/bilingual_label.dart';
import '../providers/sale_providers.dart';
import '../widgets/sale_list_tile.dart';

/// Sales register — today's and past sale entries.
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
    final paymentFilter = ref.watch(salePaymentFilterProvider);

    return Scaffold(
      backgroundColor: ColorPalette.background,
      appBar: AppBar(
        backgroundColor: ColorPalette.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const BilingualLabel(
          english: 'Sale',
          hindi: 'Sale ka register',
          compact: true,
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(RouteNames.salesNew),
        backgroundColor: ColorPalette.purple,
        icon: const Icon(Icons.edit_note_rounded),
        label: const Text('Record Sale'),
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
                          ref.read(salePaymentFilterProvider.notifier).state = null,
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Abhi mila',
                      selected: paymentFilter == PaymentMode.cash,
                      onSelected: () => ref
                          .read(salePaymentFilterProvider.notifier)
                          .state = PaymentMode.cash,
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Udhaar',
                      selected: paymentFilter == PaymentMode.credit,
                      onSelected: () => ref
                          .read(salePaymentFilterProvider.notifier)
                          .state = PaymentMode.credit,
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
                  title: 'Sales load nahi ho payi',
                  message: error.toString(),
                  actionLabel: 'Try Again',
                  onAction: () => ref.invalidate(saleListProvider),
                ),
                data: (sales) {
                  if (sales.isEmpty) {
                    return const Center(
                      child: BilingualLabel(
                        english: 'No sales recorded yet',
                        hindi: 'Pehli sale likho',
                      ),
                    );
                  }

                  return RefreshIndicator(
                    color: ColorPalette.purple,
                    onRefresh: () async => ref.invalidate(saleListProvider),
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 96),
                      itemCount: sales.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final entry = sales[index];
                        return SaleListTile(
                          entry: entry,
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
