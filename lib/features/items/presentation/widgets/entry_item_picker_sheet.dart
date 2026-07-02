import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/item_units.dart';
import '../../../../core/di/data_revision.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/buttons/app_primary_button.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';
import '../../../../shared/widgets/labels/bilingual_label.dart';
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
                english: 'Goods',
                hindi: 'Naam',
                controller: _nameController,
                validator: (v) => Validators.requiredText(v, fieldName: 'Item name'),
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
                  english: 'Unit',
                  hindi: 'Ikai',
                  controller: _customUnitController,
                  validator: (v) => Validators.requiredText(v, fieldName: 'Unit'),
                ),
              ],
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
    );
  }
}
