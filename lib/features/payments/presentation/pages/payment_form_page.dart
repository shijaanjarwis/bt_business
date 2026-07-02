import 'package:bt_business/core/errors/user_error_messages.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/data_revision.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/branding/developer_footer.dart';
import '../../../../shared/widgets/buttons/app_primary_button.dart';
import '../../../../shared/widgets/feedback/app_error_view.dart';
import '../../../../shared/widgets/feedback/app_loading_view.dart';
import '../../../../shared/widgets/inputs/app_party_picker_field.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';
import '../../../../shared/widgets/inputs/reminder_date_field.dart';
import '../../../../shared/widgets/labels/bilingual_label.dart';
import '../../../../shared/widgets/layout/app_form_section.dart';
import '../../../../shared/widgets/pickers/show_party_picker.dart';
import '../../../../shared/widgets/scaffold/app_register_app_bar.dart';
import '../../../ledger/domain/entities/party.dart';
import '../../../ledger/domain/entities/party_type.dart';
import '../../../ledger/presentation/providers/party_providers.dart';
import '../../domain/entities/payment_register_entry.dart';
import '../providers/payment_providers.dart';

enum PaymentFormMode { received, paid }

const _quickAmounts = [500, 1000, 2000, 5000, 10000];

/// Fast jama / paise diye entry — under 10 seconds.
class PaymentFormPage extends ConsumerStatefulWidget {
  const PaymentFormPage({
    super.key,
    required this.mode,
    this.paymentId,
    this.initialPartyId,
  });

  final PaymentFormMode mode;
  final String? paymentId;
  final String? initialPartyId;

  bool get isEdit => paymentId != null;

  @override
  ConsumerState<PaymentFormPage> createState() => _PaymentFormPageState();
}

class _PaymentFormPageState extends ConsumerState<PaymentFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  Party? _selectedParty;
  DateTime _dateTime = DateTime.now();
  PaymentRegisterEntry? _existing;
  late PaymentFormMode _mode = widget.mode;
  bool _initialized = false;
  bool _editHydrated = false;
  bool _isSaving = false;
  bool _isDeleting = false;
  DateTime? _reminderDate;

  bool get isReceived => _mode == PaymentFormMode.received;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant PaymentFormPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.paymentId != widget.paymentId) {
      _editHydrated = false;
      _existing = null;
    }
  }

  void _applyEntry(PaymentRegisterEntry entry) {
    if (_editHydrated) return;
    _existing = entry;
    _mode = entry.isReceived ? PaymentFormMode.received : PaymentFormMode.paid;
    _dateTime = entry.createdAt;
    _amountController.text = _formatAmount(entry.amount);
    _noteController.text = entry.note ?? '';
    _reminderDate = entry.reminderDate;
    _selectedParty = Party(
      id: entry.partyId,
      businessId: '',
      name: entry.partyName,
      type: PartyType.both,
      phone: entry.partyPhone,
      address: '',
      openingBalance: 0,
      balance: 0,
      isActive: true,
      createdAt: entry.createdAt,
      updatedAt: entry.createdAt,
    );
    _editHydrated = true;
  }

  Future<void> _loadInitialParty() async {
    if (_initialized || widget.initialPartyId == null) return;
    final result = await ref.read(getPartyUseCaseProvider)(widget.initialPartyId!);
    final party = result.valueOrNull;
    if (party != null && mounted) {
      setState(() => _selectedParty = party);
    }
  }

  String _formatAmount(double value) {
    if (value == value.roundToDouble()) return value.round().toString();
    return value.toStringAsFixed(2);
  }

  void _setQuickAmount(int amount) {
    setState(() => _amountController.text = amount.toString());
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateTime,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _dateTime = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _dateTime.hour,
          _dateTime.minute,
        );
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dateTime),
    );
    if (picked != null) {
      setState(() {
        _dateTime = DateTime(
          _dateTime.year,
          _dateTime.month,
          _dateTime.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  Future<void> _save() async {
    if (_selectedParty == null) {
      _showMessage('Party chuniye');
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    final amount =
        double.tryParse(_amountController.text.replaceAll(',', '').trim()) ?? 0;
    if (amount <= 0) {
      _showMessage('Sahi rashi likhein');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final result = await ref.read(savePaymentProvider)(
        isReceived: isReceived,
        partyId: _selectedParty!.id,
        amount: amount,
        dateTime: _dateTime,
        note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
        id: _existing?.id,
        reminderDate: _reminderDate,
      );

      if (result.isFailure) {
        _showMessage(result.failureOrNull!.message);
        return;
      }

      notifyDataChanged(ref);
      ref.invalidate(paymentListProvider);
      if (!mounted) return;
      if (widget.isEdit) {
        context.pop();
      } else {
        context.go(RouteNames.payments);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _handleDelete() async {
    final id = _existing?.id;
    if (id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isReceived ? 'Yeh jama delete karein?' : 'Yeh payment delete karein?'),
        content: const Text('Entry hat jayegi aur hisaab wapas adjust ho jayega.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const BilingualLabel(
              english: 'Cancel',
              hindi: 'Cancel',
              compact: true,
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const BilingualLabel(
              english: 'Delete',
              hindi: 'Delete Karein',
              compact: true,
              englishStyle: TextStyle(color: ColorPalette.destructive),
              hindiStyle: TextStyle(color: ColorPalette.destructive),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isDeleting = true);
    try {
      final result = await ref.read(deletePaymentProvider)(id);
      if (result.isFailure) {
        _showMessage(result.failureOrNull!.message);
        return;
      }
      notifyDataChanged(ref);
      ref.invalidate(paymentListProvider);
      if (mounted) context.pop();
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isEdit) {
      final paymentAsync = ref.watch(paymentDetailProvider(widget.paymentId!));
      return paymentAsync.when(
        loading: () => const Scaffold(body: AppLoadingView()),
        error: (error, _) => Scaffold(
          body: AppErrorView(
            title: 'Entry load nahi ho payi',
            message: UserErrorMessages.from(error),
            actionEnglish: 'Back', actionHindi: 'Wapas',
            onAction: () => context.pop(),
          ),
        ),
        data: (entry) {
          if (entry == null) {
            return Scaffold(
              body: AppErrorView(
                title: 'Entry nahi mili',
                message: 'Yeh payment ab available nahi hai.',
                actionEnglish: 'Back', actionHindi: 'Wapas',
                onAction: () => context.pop(),
              ),
            );
          }
          if (!_editHydrated) {
            _applyEntry(entry);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() {});
            });
            return const Scaffold(body: AppLoadingView());
          }
          return _buildForm();
        },
      );
    }

    if (!_initialized) {
      _initialized = true;
      _loadInitialParty();
    }

    return _buildForm();
  }

  Widget _buildForm() {
    final englishTitle = widget.isEdit
        ? (isReceived ? 'Edit Cash Received' : 'Edit Payment')
        : (isReceived ? 'Cash Received' : 'Payment');
    final hindiTitle = widget.isEdit
        ? (isReceived ? 'Paise Mile Badlo' : 'Paise Diya Badlo')
        : (isReceived ? 'Paise Mile' : 'Paise Diya');

    return Scaffold(
      backgroundColor: ColorPalette.background,
      appBar: AppRegisterAppBar(
        english: englishTitle,
        hindi: hindiTitle,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  children: [
                    AppPartyPickerField(
                      party: _selectedParty,
                      onChanged: (party) => setState(() => _selectedParty = party),
                      scope: PartyPickerScope.register,
                      allowClear: false,
                    ),
                    const SizedBox(height: 12),
                    AppFormSection(
                      english: 'Amount',
                      hindi: 'Rashi',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: _amountController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                            ],
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                            ),
                            decoration: const InputDecoration(
                              prefixText: '₹ ',
                              hintText: '0',
                              filled: true,
                              fillColor: ColorPalette.fieldFill,
                              border: OutlineInputBorder(
                                borderSide: BorderSide.none,
                                borderRadius: BorderRadius.all(Radius.circular(12)),
                              ),
                            ),
                            validator: Validators.positiveAmount,
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _quickAmounts.map((amount) {
                              return ActionChip(
                                label: Text('₹$amount'),
                                onPressed: () => _setQuickAmount(amount),
                                backgroundColor: ColorPalette.background,
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    AppFormSection(
                      english: 'Date · Time',
                      hindi: 'Tareekh · Samay',
                      child: Column(
                        children: [
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Tareekh'),
                            subtitle: Text(DateFormatter.shortDate(_dateTime)),
                            trailing: const Icon(Icons.calendar_today_rounded, size: 20),
                            onTap: _pickDate,
                          ),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Samay'),
                            subtitle: Text(DateFormat('h:mm a').format(_dateTime)),
                            trailing: const Icon(Icons.access_time_rounded, size: 20),
                            onTap: _pickTime,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    AppFormSection(
                      english: 'Reminder',
                      hindi: 'Reminder',
                      child: ReminderDateField(
                        reminderDate: _reminderDate,
                        onChanged: (date) => setState(() => _reminderDate = date),
                      ),
                    ),
                    const SizedBox(height: 12),
                    AppFormSection(
                      english: 'Note',
                      hindi: 'Note',
                      child: AppTextField(
                        english: 'Note',
                        hindi: 'Note',
                        helper: 'Optional',
                        controller: _noteController,
                        maxLines: 2,
                      ),
                    ),
                    if (widget.isEdit) ...[
                      const SizedBox(height: 16),
                      AppPrimaryButton(
                        english: 'Delete',
                        hindi: 'Delete Karein',
                        destructive: true,
                        compact: true,
                        isLoading: _isDeleting,
                        onPressed: _isDeleting ? null : _handleDelete,
                      ),
                    ],
                    const DeveloperFooter(),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.fromLTRB(
                  20,
                  16,
                  20,
                  16 + MediaQuery.paddingOf(context).bottom,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: AppPrimaryButton(
                  english: 'Save',
                  hindi: 'Save Karein',
                  isLoading: _isSaving,
                  onPressed: _save,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
