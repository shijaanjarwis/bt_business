import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/color_palette.dart';
import '../../../../shared/widgets/feedback/app_error_view.dart';
import '../../../../shared/widgets/feedback/app_loading_view.dart';
import '../../../../shared/widgets/labels/bilingual_label.dart';
import '../providers/item_providers.dart';
import '../widgets/entry_item_picker_sheet.dart';

/// Flat item master list — one simple list, no groups or categories.
class ItemListPage extends ConsumerWidget {
  const ItemListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(itemListProvider);

    return Scaffold(
      backgroundColor: ColorPalette.background,
      appBar: AppBar(
        backgroundColor: ColorPalette.background,
        elevation: 0,
        title: const BilingualLabel(
          english: 'Items',
          hindi: 'Maal ka list — simple item master',
          compact: true,
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            builder: (context) => const QuickItemCreateSheet(
              initialName: '',
              mode: EntryItemMode.sale,
            ),
          );
          ref.invalidate(itemListProvider);
        },
        backgroundColor: ColorPalette.purple,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Item'),
      ),
      body: SafeArea(
        child: itemsAsync.when(
          loading: () => const AppLoadingView(),
          error: (error, _) => AppErrorView(
            title: 'Items load nahi ho paye',
            message: error.toString(),
            actionLabel: 'Try Again',
            onAction: () => ref.invalidate(itemListProvider),
          ),
          data: (items) {
            if (items.isEmpty) {
              return const Center(
                child: BilingualLabel(
                  english: 'No items yet',
                  hindi: 'Sale ya kharid se pehla maal jodein',
                ),
              );
            }

            return RefreshIndicator(
              color: ColorPalette.purple,
              onRefresh: () async => ref.invalidate(itemListProvider),
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 96),
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Stock: ${item.openingStock} ${item.unit}',
                            style: const TextStyle(color: Color(0xFF636366)),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
