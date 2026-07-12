import 'package:bt_business/core/errors/user_error_messages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/item_units.dart';
import '../../../../core/di/data_revision.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../core/utils/rate_field_utils.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/branding/developer_footer.dart';
import '../../../../shared/widgets/buttons/app_primary_button.dart';
import '../../../../shared/widgets/dialogs/confirmation_dialog.dart';
import '../../../../shared/widgets/feedback/app_error_view.dart';
import '../../../../shared/widgets/feedback/app_loading_view.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';
import '../../../../shared/widgets/labels/app_form_field_label.dart';
import '../../../../shared/widgets/layout/main_shell_insets.dart';
import '../../../../shared/widgets/layout/responsive_form_container.dart';
import '../../../../shared/widgets/pickers/show_unit_picker.dart';
import '../../../../shared/widgets/scaffold/app_register_app_bar.dart';
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
  final _purchaseRateController = TextEditingController();
  final _saleRateController = TextEditingController();

  Item? _existingItem;
  String _selectedUnit = ItemUnits.defaultUnit;
  bool _isSaving = false;
  bool _isDeleting = false;
  bool _itemApplied = false;

  @override
  void dispose() {
    _nameController.dispose();
    _purchaseRateController.dispose();
    _saleRateController.dispose();
    super.dispose();
  }

  void _applyItem(Item item) {
    if (_itemApplied) return;
    _existingItem = item;
    _nameController.text = item.name;
    _selectedUnit = item.unit;
    if (item.purchasePrice > 0) {
      _purchaseRateController.text = RateFieldUtils.initialText(item.purchasePrice);
    }
    if (item.salePrice > 0) {
      _saleRateController.text = RateFieldUtils.initialText(item.salePrice);
    }
    _itemApplied = true;
  }

  String get _unit => _selectedUnit;

  Future<void> _pickOtherUnit() async {
    final picked = await showUnitPicker(context);
    if (picked != null && mounted) {
      setState(() => _selectedUnit = picked);
    }
  }

  bool get _isOtherUnit => !ItemUnits.presets.contains(_selectedUnit);

  double _parseRate(TextEditingController controller) {
    return RateFieldUtils.parse(controller.text);
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

    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Yeh maal delete karein?',
      message:
          'Naam list se hat jayega. Purani bikri/kharid entries par asar nahi padega.',
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
            message: UserErrorMessages.from(error),
            actionEnglish: 'Back', actionHindi: 'Wapas',
            onAction: () => context.pop(),
          ),
        ),
        data: (item) {
          if (item == null) {
            return Scaffold(
              body: AppErrorView(
                title: 'Nahi mila',
                message: 'Yeh maal nahi mila.',
                actionEnglish: 'Back', actionHindi: 'Wapas',
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
      appBar: AppRegisterAppBar(
        english: widget.isEdit ? 'Edit Goods' : 'Goods',
        hindi: widget.isEdit ? 'Maal Badlo' : 'Maal Jodein',
        actions: [
          if (widget.isEdit)
            IconButton(
              onPressed: _isDeleting ? null : _handleDelete,
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: ColorPalette.destructive,
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsets.fromLTRB(20, 0, 20, MainShellInsets.scrollBottom(context)),
            children: [
              ResponsiveFormContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppTextField(
                      english: 'Goods Name',
                      hindi: 'Maal ka Naam',
                      controller: _nameController,
                      textInputAction: TextInputAction.next,
                      validator: (value) =>
                          Validators.requiredText(value, fieldName: 'Maal ka naam'),
                    ),
                    const SizedBox(height: 20),
                    const AppFormFieldLabel(
                      english: 'Unit',
                      hindi: 'Ikai',
                      compact: true,
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ...ItemUnits.presets.map((unit) {
                          final selected = !_isOtherUnit && _selectedUnit == unit;
                          return ChoiceChip(
                            label: Text(unit),
                            selected: selected,
                            onSelected: (_) => setState(() => _selectedUnit = unit),
                            selectedColor: ColorPalette.purple.withValues(alpha: 0.15),
                          );
                        }),
                        ChoiceChip(
                          label: Text(_isOtherUnit ? _selectedUnit : 'Other · Aur'),
                          selected: _isOtherUnit,
                          onSelected: (_) => _pickOtherUnit(),
                          selectedColor: ColorPalette.purple.withValues(alpha: 0.15),
                        ),
                      ],
                    ),
                    if (_isOtherUnit) ...[
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: _pickOtherUnit,
                        icon: const Icon(Icons.search_rounded, size: 18),
                        label: const Text('Unit badlein'),
                      ),
                    ],
                    const SizedBox(height: 20),
                    AppTextField(
                      english: 'Purchase Rate',
                      hindi: 'Kharid Daam',
                      controller: _purchaseRateController,
                      helper: 'Optional',
                      hintText: 'Enter Rate',
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      textInputAction: TextInputAction.next,
                      validator: Validators.nonNegativeAmount,
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      english: 'Sale Rate',
                      hindi: 'Bikri Daam',
                      controller: _saleRateController,
                      helper: 'Optional',
                      hintText: 'Enter Rate',
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      textInputAction: TextInputAction.done,
                      validator: Validators.nonNegativeAmount,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Daam sirf suggestion hai — bikri/kharid likhte waqt badal sakte hain.',
                      style: TextStyle(fontSize: 12, color: ColorPalette.labelTertiary),
                    ),
                    const SizedBox(height: 28),
                    AppPrimaryButton(
                      english: widget.isEdit ? 'Save' : 'Add',
                      hindi: widget.isEdit ? 'Save Karein' : 'Jodein',
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
