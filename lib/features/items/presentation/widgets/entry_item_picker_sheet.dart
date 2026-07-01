import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/item_units.dart';
import '../../../../core/di/data_revision.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/buttons/app_primary_button.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';
import '../../../../shared/widgets/labels/bilingual_label.dart';
import '../../domain/entities/item.dart';
import '../../domain/repositories/item_repository.dart';
import '../providers/item_providers.dart';

/// Whether the picker defaults to sale or purchase price.
enum EntryItemMode { sale, purchase }

/// Pick an existing item or create a new one inline while recording an entry.
class EntryItemPickerSheet extends ConsumerStatefulWidget {
  const EntryItemPickerSheet({
    super.key,
    required this.mode,
  });

  final EntryItemMode mode;

  @override
  ConsumerState<EntryItemPickerSheet> createState() =>
      _EntryItemPickerSheetState();
}

class _EntryItemPickerSheetState extends ConsumerState<EntryItemPickerSheet> {
  final _queryController = TextEditingController();

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _createNewItem() async {
    final name = _queryController.text.trim();
    if (name.isEmpty) return;

    final item = await showModalBottomSheet<Item>(
      context: context,
      isScrollControlled: true,
      builder: (context) => QuickItemCreateSheet(
        initialName: name,
        mode: widget.mode,
      ),
    );

    if (item != null && mounted) {
      Navigator.pop(context, item);
    }
  }

  String _priceLabel(Item item) {
    final price = widget.mode == EntryItemMode.sale
        ? item.salePrice
        : item.purchasePrice;
    if (price > 0) {
      return '${item.unit} · ₹${price.toStringAsFixed(price % 1 == 0 ? 0 : 2)}';
    }
    return item.unit;
  }

  @override
  Widget build(BuildContext context) {
    final query = _queryController.text;
    final itemsAsync = ref.watch(itemSearchProvider(query));
    final trimmed = query.trim();

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      builder: (context, scrollController) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const BilingualLabel(
                english: 'Select or Add Item',
                hindi: 'Maal chuniye ya naya jodein',
                compact: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _queryController,
                autofocus: true,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: 'Type item name…',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
              if (trimmed.isNotEmpty) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _createNewItem,
                  icon: const Icon(Icons.add_rounded, color: ColorPalette.purple),
                  label: Text('Add "$trimmed" as new item · Naya maal jodein'),
                ),
              ],
              const SizedBox(height: 12),
              Expanded(
                child: itemsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Text(error.toString()),
                  data: (items) {
                    if (items.isEmpty && trimmed.isEmpty) {
                      return const Center(
                        child: BilingualLabel(
                          english: 'No items yet',
                          hindi: 'Upar type karke pehla maal jodein',
                          compact: true,
                        ),
                      );
                    }
                    if (items.isEmpty) {
                      return const Center(
                        child: BilingualLabel(
                          english: 'No match — tap Add above',
                          hindi: 'Match nahi mila — upar Add dabayein',
                          compact: true,
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: scrollController,
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return ListTile(
                          title: Text(item.name),
                          subtitle: Text(_priceLabel(item)),
                          onTap: () => Navigator.pop(context, item),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Quick item creation without leaving the entry screen.
class QuickItemCreateSheet extends ConsumerStatefulWidget {
  const QuickItemCreateSheet({
    super.key,
    required this.initialName,
    required this.mode,
  });

  final String initialName;
  final EntryItemMode mode;

  @override
  ConsumerState<QuickItemCreateSheet> createState() => _QuickItemCreateSheetState();
}

class _QuickItemCreateSheetState extends ConsumerState<QuickItemCreateSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(text: widget.initialName);
  late final _customUnitController = TextEditingController();
  String _selectedUnit = ItemUnits.defaultUnit;
  bool _useCustomUnit = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _customUnitController.dispose();
    super.dispose();
  }

  String get _unit =>
      _useCustomUnit ? _customUnitController.text.trim() : _selectedUnit;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final result = await ref.read(saveItemUseCaseProvider)(
        SaveItemInput(
          name: _nameController.text,
          unit: _unit,
        ),
      );

      if (result.isFailure) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result.failureOrNull!.message)),
          );
        }
        return;
      }

      notifyDataChanged(ref);
      if (mounted) Navigator.pop(context, result.valueOrNull);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              const BilingualLabel(
                english: 'New Item',
                hindi: 'Naya maal jodein',
                compact: true,
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _nameController,
                label: 'Item Name · Naam',
                validator: (v) => Validators.requiredText(v, fieldName: 'Item name'),
              ),
              const SizedBox(height: 12),
              const BilingualLabel(
                english: 'Unit · Ikai',
                hindi: 'Piece, Kg, Box…',
                compact: true,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ...ItemUnits.presets.map((unit) {
                    final selected = !_useCustomUnit && _selectedUnit == unit;
                    return ChoiceChip(
                      label: Text(unit),
                      selected: selected,
                      onSelected: (_) => setState(() {
                        _useCustomUnit = false;
                        _selectedUnit = unit;
                      }),
                    );
                  }),
                  ChoiceChip(
                    label: const Text('Other · Aur'),
                    selected: _useCustomUnit,
                    onSelected: (_) => setState(() => _useCustomUnit = true),
                  ),
                ],
              ),
              if (_useCustomUnit) ...[
                const SizedBox(height: 12),
                AppTextField(
                  controller: _customUnitController,
                  label: 'Unit name · Ikai likhein',
                  validator: (v) => Validators.requiredText(v, fieldName: 'Unit'),
                ),
              ],
              const SizedBox(height: 20),
              AppPrimaryButton(
                label: 'Save · Save karein',
                isLoading: _isSaving,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
