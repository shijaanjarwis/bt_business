import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/item_units.dart';
import '../../../../core/di/data_revision.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/branding/developer_footer.dart';
import '../../../../shared/widgets/buttons/app_primary_button.dart';
import '../../../../shared/widgets/feedback/app_error_view.dart';
import '../../../../shared/widgets/feedback/app_loading_view.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';
import '../../../../shared/widgets/layout/responsive_form_container.dart';
import '../../domain/entities/item.dart';
import '../../domain/repositories/item_repository.dart';
import '../providers/item_providers.dart';

enum ItemFormMode { create, edit }

/// Add or edit maal — naam, unit, optional default rates only.
class ItemFormPage extends ConsumerStatefulWidget {
  const ItemFormPage({
    super.key,
    required this.mode,
    this.itemId,
  });

  final ItemFormMode mode;
  final String? itemId;

  bool get isEdit => mode == ItemFormMode.edit;

  @override
  ConsumerState<ItemFormPage> createState() => _ItemFormPageState();
}

class _ItemFormPageState extends ConsumerState<ItemFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _customUnitController = TextEditingController();
  final _purchaseRateController = TextEditingController();
  final _saleRateController = TextEditingController();

  Item? _existingItem;
  String _selectedUnit = ItemUnits.defaultUnit;
  bool _useCustomUnit = false;
  bool _isSaving = false;
  bool _isDeleting = false;
  bool _itemApplied = false;

  @override
  void dispose() {
    _nameController.dispose();
    _customUnitController.dispose();
    _purchaseRateController.dispose();
    _saleRateController.dispose();
    super.dispose();
  }

  void _applyItem(Item item) {
    if (_itemApplied) return;
    _existingItem = item;
    _nameController.text = item.name;
    if (ItemUnits.presets.contains(item.unit)) {
      _selectedUnit = item.unit;
      _useCustomUnit = false;
    } else {
      _useCustomUnit = true;
      _customUnitController.text = item.unit;
    }
    if (item.purchasePrice > 0) {
      _purchaseRateController.text = item.purchasePrice.toString();
    }
    if (item.salePrice > 0) {
      _saleRateController.text = item.salePrice.toString();
    }
    _itemApplied = true;
  }

  String get _unit =>
      _useCustomUnit ? _customUnitController.text.trim() : _selectedUnit;

  double _parseRate(TextEditingController controller) {
    final text = controller.text.replaceAll(',', '').trim();
    if (text.isEmpty) return 0;
    return double.tryParse(text) ?? 0;
  }

  SaveItemInput _buildInput() {
    return SaveItemInput(
      id: _existingItem?.id,
      name: _nameController.text,
      unit: _unit,
      openingStock: _existingItem?.openingStock ?? 0, // internal compatibility
      purchasePrice: _parseRate(_purchaseRateController),
      salePrice: _parseRate(_saleRateController),
      gstRate: _existingItem?.gstRate ?? 0, // internal compatibility
    );
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final result = await ref.read(saveItemUseCaseProvider)(_buildInput());
      if (result.isFailure) {
        _showMessage(result.failureOrNull!.message);
        return;
      }

      notifyDataChanged(ref);
      if (mounted) context.pop();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _handleDelete() async {
    final itemId = _existingItem?.id;
    if (itemId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yeh maal delete karein?'),
        content: const Text(
          'Naam list se hat jayega. Purani bikri/kharid entries par asar nahi padega.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Rahne dein'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isDeleting = true);
    try {
      final result = await ref.read(deleteItemUseCaseProvider)(itemId);
      if (result.isFailure) {
        _showMessage(result.failureOrNull!.message);
        return;
      }
      notifyDataChanged(ref);
      if (mounted) context.pop();
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isEdit && widget.itemId != null) {
      final itemAsync = ref.watch(itemDetailProvider(widget.itemId!));
      return itemAsync.when(
        loading: () => const Scaffold(body: AppLoadingView()),
        error: (error, _) => Scaffold(
          body: AppErrorView(
            title: 'Load nahi ho paya',
            message: error.toString(),
            actionLabel: 'Wapas',
            onAction: () => context.pop(),
          ),
        ),
        data: (item) {
          if (item == null) {
            return Scaffold(
              body: AppErrorView(
                title: 'Nahi mila',
                message: 'Yeh maal nahi mila.',
                actionLabel: 'Wapas',
                onAction: () => context.pop(),
              ),
            );
          }
          _applyItem(item);
          return _buildForm();
        },
      );
    }

    return _buildForm();
  }

  Widget _buildForm() {
    return Scaffold(
      backgroundColor: ColorPalette.background,
      appBar: AppBar(
        backgroundColor: ColorPalette.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          widget.isEdit ? 'Maal Badlo' : 'Maal Jodein',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        actions: [
          if (widget.isEdit)
            IconButton(
              onPressed: _isDeleting ? null : _handleDelete,
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
            ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            children: [
              ResponsiveFormContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppTextField(
                      controller: _nameController,
                      label: 'Maal ka Naam',
                      textInputAction: TextInputAction.next,
                      validator: (value) =>
                          Validators.requiredText(value, fieldName: 'Maal ka naam'),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Unit · Ikai',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Color(0xFF636366),
                      ),
                    ),
                    const SizedBox(height: 10),
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
                            selectedColor: ColorPalette.purple.withValues(alpha: 0.15),
                          );
                        }),
                        ChoiceChip(
                          label: const Text('Aur'),
                          selected: _useCustomUnit,
                          onSelected: (_) => setState(() => _useCustomUnit = true),
                          selectedColor: ColorPalette.purple.withValues(alpha: 0.15),
                        ),
                      ],
                    ),
                    if (_useCustomUnit) ...[
                      const SizedBox(height: 12),
                      AppTextField(
                        controller: _customUnitController,
                        label: 'Unit likhein',
                        validator: (value) =>
                            Validators.requiredText(value, fieldName: 'Unit'),
                      ),
                    ],
                    const SizedBox(height: 20),
                    AppTextField(
                      controller: _purchaseRateController,
                      label: 'Kharid Daam (optional)',
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      textInputAction: TextInputAction.next,
                      validator: Validators.nonNegativeAmount,
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: _saleRateController,
                      label: 'Bikri Daam (optional)',
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      textInputAction: TextInputAction.done,
                      validator: Validators.nonNegativeAmount,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Daam sirf suggestion hai — bikri/kharid likhte waqt badal sakte hain.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF8E8E93)),
                    ),
                    const SizedBox(height: 28),
                    AppPrimaryButton(
                      label: widget.isEdit ? 'Save Karein' : 'Maal Jodein',
                      isLoading: _isSaving,
                      onPressed: _handleSave,
                    ),
                  ],
                ),
              ),
              const DeveloperFooter(),
            ],
          ),
        ),
      ),
    );
  }
}
