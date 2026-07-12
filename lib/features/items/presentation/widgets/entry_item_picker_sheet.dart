import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/item_units.dart';
import '../../../../core/di/data_revision.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/buttons/app_primary_button.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';
import '../../../../shared/widgets/labels/bilingual_label.dart';
import '../../../../shared/widgets/pickers/show_unit_picker.dart';
import '../../domain/repositories/item_repository.dart';
import '../providers/item_providers.dart';

/// Whether the picker defaults to sale or purchase price.
enum EntryItemMode { sale, purchase }

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
  String _selectedUnit = ItemUnits.defaultUnit;

  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  bool get _isOtherUnit => !ItemUnits.presets.contains(_selectedUnit);

  Future<void> _pickOtherUnit() async {
    final picked = await showUnitPicker(context);
    if (picked != null && mounted) {
      setState(() => _selectedUnit = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final result = await ref.read(saveItemUseCaseProvider)(
        SaveItemInput(
          name: _nameController.text,
          unit: _selectedUnit,
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
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final maxHeight = MediaQuery.sizeOf(context).height * 0.92 - viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Flexible(
                    child: SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const BilingualLabel(
                            english: 'New Item',
                            hindi: 'Naya maal jodein',
                            compact: true,
                          ),
                          const SizedBox(height: 16),
                          AppTextField(
                            english: 'Goods',
                            hindi: 'Naam',
                            controller: _nameController,
                            validator: (v) =>
                                Validators.requiredText(v, fieldName: 'Item name'),
                          ),
                          const SizedBox(height: 12),
                          const BilingualLabel(
                            english: 'Unit',
                            hindi: 'Piece, Kg, Box…',
                            compact: true,
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              ...ItemUnits.presets.map((unit) {
                                final selected =
                                    !_isOtherUnit && _selectedUnit == unit;
                                return ChoiceChip(
                                  label: Text(unit),
                                  selected: selected,
                                  onSelected: (_) =>
                                      setState(() => _selectedUnit = unit),
                                );
                              }),
                              ChoiceChip(
                                label: Text(
                                  _isOtherUnit ? _selectedUnit : 'Other · Aur',
                                ),
                                selected: _isOtherUnit,
                                onSelected: (_) => _pickOtherUnit(),
                              ),
                            ],
                          ),
                          if (_isOtherUnit) ...[
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: _pickOtherUnit,
                              icon: const Icon(Icons.search_rounded, size: 18),
                              label: const Text('Unit library kholein'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  AppPrimaryButton(
                    english: 'Save',
                    hindi: 'Save Karein',
                    isLoading: _isSaving,
                    onPressed: _save,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
