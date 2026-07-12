import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/items/domain/entities/item.dart';
import '../../../features/items/presentation/providers/item_providers.dart';
import '../../../features/items/presentation/widgets/entry_item_picker_sheet.dart';
import '../sheets/app_search_picker_sheet.dart';

/// Opens the unified item search picker sheet.
Future<Item?> showItemPicker(
  BuildContext context,
  WidgetRef ref, {
  EntryItemMode mode = EntryItemMode.sale,
}) {
  return AppSearchPickerSheet.show<Item>(
    context: context,
    englishTitle: 'Goods',
    hindiTitle: 'Maal Chunein',
    emptyEnglish: 'No item found',
    emptyHindi: 'Koi maal nahi mila',
    createLabelEnglish: 'Add new item',
    createLabelHindi: 'Naya maal jodein',
    watchItems: (ref, query) => ref.watch(itemSearchProvider(query)),
    itemBuilder: (context, item, onSelect) {
      final price = mode == EntryItemMode.sale ? item.salePrice : item.purchasePrice;
      final priceLabel = price > 0
          ? '${item.unit} · ₹${price.toStringAsFixed(price % 1 == 0 ? 0 : 2)}'
          : item.unit;
      return ListTile(
        title: Text(item.name),
        subtitle: Text(priceLabel),
        onTap: onSelect,
      );
    },
    onCreate: (name) async {
      if (!context.mounted) return;
      final item = await showModalBottomSheet<Item>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.white,
        builder: (context) => QuickItemCreateSheet(
          initialName: name,
          mode: mode,
        ),
      );
      if (item != null && context.mounted) {
        Navigator.pop(context, item);
      }
    },
  );
}
