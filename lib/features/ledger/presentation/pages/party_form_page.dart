import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/data_revision.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/branding/developer_footer.dart';
import '../../../../shared/widgets/buttons/app_primary_button.dart';
import '../../../../shared/widgets/feedback/app_error_view.dart';
import '../../../../shared/widgets/feedback/app_loading_view.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';
import '../../../../shared/widgets/layout/responsive_form_container.dart';
import '../../../../shared/widgets/labels/bilingual_label.dart';
import '../../domain/entities/opening_balance_direction.dart';
import '../../domain/entities/party.dart';
import '../../domain/entities/party_type.dart';
import '../../domain/repositories/party_repository.dart';
import '../providers/party_providers.dart';

enum PartyFormMode { create, edit }

/// Add or edit a name in the hisaab notebook — nothing else required.
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
  final _previousBalanceController = TextEditingController();

  Party? _existingParty;
  OpeningBalanceDirection _previousDirection = OpeningBalanceDirection.receivable;
  bool _isSaving = false;
  bool _isDeleting = false;
  bool _hasOtherTransactions = false;
  bool _partyApplied = false;
  bool _formReady = false;
  bool _txChecked = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _previousBalanceController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant PartyFormPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.partyId != widget.partyId) {
      _partyApplied = false;
      _formReady = false;
      _txChecked = false;
      _hasOtherTransactions = false;
    }
  }

  void _applyParty(Party party) {
    if (_partyApplied && _existingParty?.id == party.id) return;
    _existingParty = party;
    _nameController.text = party.name;
    _phoneController.text = party.phone;
    if (party.openingAmount > 0) {
      _previousBalanceController.text = party.openingAmount.toString();
      _previousDirection = party.openingDirection;
    } else {
      _previousBalanceController.clear();
      _previousDirection = OpeningBalanceDirection.receivable;
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
    final previousAmount = double.tryParse(
          _previousBalanceController.text.replaceAll(',', '').trim(),
        ) ??
        0;

    return SavePartyInput(
      id: _existingParty?.id,
      name: _nameController.text,
      type: PartyType.both,
      phone: _phoneController.text,
      address: '',
      openingAmount: previousAmount,
      openingDirection: _previousDirection,
      isActive: true,
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
        title: const Text('Delete this name?'),
        content: const Text('Yeh hisaab hamesha ke liye delete ho jayega.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    if (_hasOtherTransactions) {
      _showMessage(
        'Is party ki purani entries hain — pehle unhe theek karein, phir naam delete karein.',
      );
      return;
    }

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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isEdit && widget.partyId != null) {
      final partyAsync = ref.watch(partyDetailProvider(widget.partyId!));
      return partyAsync.when(
        loading: () => const Scaffold(body: AppLoadingView()),
        error: (error, _) => Scaffold(
          body: AppErrorView(
            title: 'Load nahi ho payi',
            message: error.toString(),
            actionLabel: 'Back',
            onAction: () => context.pop(),
          ),
        ),
        data: (party) {
          if (party == null) {
            return Scaffold(
              body: AppErrorView(
                title: 'Not found',
                message: 'Yeh naam nahi mila.',
                actionLabel: 'Back',
                onAction: () => context.pop(),
              ),
            );
          }
          if (!_formReady) {
            _applyParty(party);
            _loadTransactionLock(party.id);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _formReady = true);
            });
            return const Scaffold(body: AppLoadingView());
          }
          return _buildForm(party.id);
        },
      );
    }

    return _buildForm(null);
  }

  Widget _buildForm(String? formKey) {
    return Scaffold(
      backgroundColor: ColorPalette.background,
      appBar: AppBar(
        backgroundColor: ColorPalette.background,
        elevation: 0,
        title: BilingualLabel(
          english: widget.isEdit ? 'Edit Name' : 'New Name',
          hindi: widget.isEdit ? 'Naam badlo' : 'Naya naam jodein',
          compact: true,
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
            key: formKey == null ? null : ValueKey(formKey),
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            children: [
              ResponsiveFormContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppTextField(
                      controller: _nameController,
                      label: 'Name · Naam',
                      textInputAction: TextInputAction.next,
                      validator: (value) =>
                          Validators.requiredText(value, fieldName: 'Name'),
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: _phoneController,
                      label: 'Mobile (optional) · Mobile',
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return null;
                        return Validators.indianPhone(value);
                      },
                    ),
                    const SizedBox(height: 16),
                    const SizedBox(height: 4),
                    const BilingualLabel(
                      english: 'Previous balance (optional)',
                      hindi: 'Pehle se baaki (optional)',
                      compact: true,
                    ),
                    const SizedBox(height: 8),
                    IgnorePointer(
                      ignoring: _hasOtherTransactions,
                      child: Opacity(
                        opacity: _hasOtherTransactions ? 0.55 : 1,
                        child: AppTextField(
                          controller: _previousBalanceController,
                          label: 'Amount · Raashi',
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          validator: Validators.nonNegativeAmount,
                        ),
                      ),
                    ),
                    if (_hasOtherTransactions)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Pehle se baaki ab badla nahi ja sakta — entries ho chuki hain.',
                          style: TextStyle(fontSize: 12, color: Colors.orange.shade800),
                        ),
                      ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: OpeningBalanceDirection.values.map((direction) {
                        final selected = _previousDirection == direction;
                        return ChoiceChip(
                          label: Text('${direction.englishLabel} · ${direction.hindiLabel}'),
                          selected: selected,
                          onSelected: _hasOtherTransactions
                              ? null
                              : (_) => setState(() => _previousDirection = direction),
                          selectedColor: ColorPalette.purple.withValues(alpha: 0.15),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 28),
                    AppPrimaryButton(
                      label: widget.isEdit ? 'Save · Save karein' : 'Add · Jodein',
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
