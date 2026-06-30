import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/data_revision.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/buttons/app_primary_button.dart';
import '../../../../shared/widgets/feedback/app_error_view.dart';
import '../../../../shared/widgets/feedback/app_loading_view.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';
import '../../../../shared/widgets/layout/app_form_section.dart';
import '../../../../shared/widgets/layout/responsive_form_container.dart';
import '../../../../shared/widgets/labels/bilingual_label.dart';
import '../../domain/entities/opening_balance_direction.dart';
import '../../domain/entities/party.dart';
import '../../domain/entities/party_type.dart';
import '../../domain/repositories/party_repository.dart';
import '../providers/party_providers.dart';
import '../widgets/party_type_selector.dart';

enum PartyFormMode { create, edit }

/// Add or edit a customer/supplier ledger entry.
class PartyFormPage extends ConsumerStatefulWidget {
  const PartyFormPage({
    super.key,
    required this.mode,
    this.partyId,
  });

  final PartyFormMode mode;
  final String? partyId;

  bool get isEdit => mode == PartyFormMode.edit;

  @override
  ConsumerState<PartyFormPage> createState() => _PartyFormPageState();
}

class _PartyFormPageState extends ConsumerState<PartyFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _gstinController = TextEditingController();
  final _openingController = TextEditingController(text: '0');
  final _creditLimitController = TextEditingController();

  Party? _existingParty;
  PartyType _type = PartyType.customer;
  OpeningBalanceDirection _openingDirection = OpeningBalanceDirection.receivable;
  bool _isActive = true;
  bool _isSaving = false;
  bool _isDeleting = false;
  bool _hasOtherTransactions = false;
  bool _partyApplied = false;
  bool _txChecked = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _gstinController.dispose();
    _openingController.dispose();
    _creditLimitController.dispose();
    super.dispose();
  }

  void _applyParty(Party party) {
    if (_partyApplied) return;
    _existingParty = party;
    _nameController.text = party.name;
    _phoneController.text = party.phone;
    _addressController.text = party.address;
    _gstinController.text = party.gstin ?? '';
    _openingController.text = party.openingAmount.toString();
    _openingDirection = party.openingDirection;
    _type = party.type;
    _isActive = party.isActive;
    if (party.creditLimit != null) {
      _creditLimitController.text = party.creditLimit!.toString();
    }
    _partyApplied = true;
  }

  void _loadTransactionLock(String partyId) {
    if (_txChecked) return;
    _txChecked = true;
    ref.read(partyRepositoryProvider).hasTransactions(partyId).then((result) {
      if (!mounted) return;
      setState(() => _hasOtherTransactions = result.valueOrNull ?? false);
    });
  }

  SavePartyInput _buildInput() {
    final openingAmount = double.tryParse(
          _openingController.text.replaceAll(',', '').trim(),
        ) ??
        0;
    final creditText = _creditLimitController.text.trim();
    final creditLimit = creditText.isEmpty
        ? null
        : double.tryParse(creditText.replaceAll(',', ''));

    return SavePartyInput(
      id: _existingParty?.id,
      name: _nameController.text,
      type: _type,
      phone: _phoneController.text,
      address: _addressController.text,
      gstin: _gstinController.text,
      openingAmount: openingAmount,
      openingDirection: _openingDirection,
      creditLimit: creditLimit,
      isActive: _isActive,
      existingCreatedAt: _existingParty?.createdAt,
      existingOpeningTransactionId: _existingParty?.openingTransactionId,
      existingBalance: _existingParty?.balance,
    );
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final result = await ref.read(savePartyUseCaseProvider)(_buildInput());
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
    final partyId = _existingParty?.id;
    if (partyId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete party?'),
        content: const Text(
          'Yeh party hamesha ke liye delete ho jayegi. Kya aap sure hain?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
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
      final result = await ref.read(deletePartyUseCaseProvider)(partyId);
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isEdit && widget.partyId != null) {
      final partyAsync = ref.watch(partyDetailProvider(widget.partyId!));
      return partyAsync.when(
        loading: () => const Scaffold(body: AppLoadingView()),
        error: (error, _) => Scaffold(
          body: AppErrorView(
            title: 'Party load nahi ho payi',
            message: error.toString(),
            actionLabel: 'Back',
            onAction: () => context.pop(),
          ),
        ),
        data: (party) {
          if (party == null) {
            return Scaffold(
              body: AppErrorView(
                title: 'Party not found',
                message: 'Yeh party ab available nahi hai.',
                actionLabel: 'Back',
                onAction: () => context.pop(),
              ),
            );
          }
          _applyParty(party);
          _loadTransactionLock(party.id);
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
        title: BilingualLabel(
          english: widget.isEdit ? 'Edit Party' : 'Add Party',
          hindi: widget.isEdit ? 'Party details badlo' : 'Naya customer/supplier',
          compact: true,
        ),
        actions: [
          if (widget.isEdit)
            IconButton(
              onPressed: _isDeleting ? null : _handleDelete,
              icon: _isDeleting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.delete_outline_rounded, color: Colors.red),
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
                    AppFormSection(
                      title: 'Basic Details',
                      child: Column(
                        children: [
                          AppTextField(
                            controller: _nameController,
                            label: 'Name · Naam',
                            textInputAction: TextInputAction.next,
                            validator: (value) =>
                                Validators.requiredText(value, fieldName: 'Name'),
                          ),
                          const SizedBox(height: 12),
                          PartyTypeSelector(
                            value: _type,
                            onChanged: (value) => setState(() => _type = value),
                          ),
                          const SizedBox(height: 12),
                          AppTextField(
                            controller: _phoneController,
                            label: 'Mobile · Mobile number',
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.next,
                            validator: Validators.requiredIndianPhone,
                          ),
                          const SizedBox(height: 12),
                          AppTextField(
                            controller: _addressController,
                            label: 'Address · Pata',
                            maxLines: 3,
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 12),
                          AppTextField(
                            controller: _gstinController,
                            label: 'GSTIN · GST number (optional)',
                            textCapitalization: TextCapitalization.characters,
                            validator: Validators.gstin,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    AppFormSection(
                      title: 'Opening Balance',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AbsorbPointer(
                            absorbing: _hasOtherTransactions,
                            child: Opacity(
                              opacity: _hasOtherTransactions ? 0.55 : 1,
                              child: AppTextField(
                                controller: _openingController,
                                label: 'Amount · Raashi',
                                keyboardType: const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return null;
                                  }
                                  return Validators.nonNegativeAmount(
                                    value,
                                    fieldName: 'opening balance',
                                  );
                                },
                              ),
                            ),
                          ),
                          if (_hasOtherTransactions)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                'Opening balance locked — transactions already exist.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange.shade800,
                                ),
                              ),
                            ),
                          const SizedBox(height: 12),
                          const BilingualLabel(
                            english: 'Balance Type',
                            hindi: 'Lena hai ya dena',
                            compact: true,
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: OpeningBalanceDirection.values.map((direction) {
                              final selected = _openingDirection == direction;
                              return ChoiceChip(
                                label: Text(direction.englishLabel),
                                selected: selected,
                                onSelected: _hasOtherTransactions
                                    ? null
                                    : (_) => setState(
                                          () => _openingDirection = direction,
                                        ),
                                selectedColor:
                                    ColorPalette.purple.withValues(alpha: 0.15),
                                labelStyle: TextStyle(
                                  color: selected
                                      ? ColorPalette.purple
                                      : const Color(0xFF636366),
                                  fontWeight:
                                      selected ? FontWeight.w600 : FontWeight.w500,
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _openingDirection.hindiLabel,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    AppFormSection(
                      title: 'Credit & Status',
                      child: Column(
                        children: [
                          AppTextField(
                            controller: _creditLimitController,
                            label: 'Credit Limit · Udhaar limit (optional)',
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: Validators.nonNegativeAmount,
                          ),
                          const SizedBox(height: 12),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Active · Chalu rakhein'),
                            subtitle: const Text(
                              'Inactive parties hide from active lists',
                            ),
                            value: _isActive,
                            activeThumbColor: ColorPalette.purple,
                            onChanged: (value) => setState(() => _isActive = value),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    AppPrimaryButton(
                      label: widget.isEdit ? 'Save Changes' : 'Add Party',
                      isLoading: _isSaving,
                      onPressed: _handleSave,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
