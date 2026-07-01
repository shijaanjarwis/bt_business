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
import '../../../../shared/widgets/inputs/app_text_field.dart';
import '../../../ledger/domain/entities/opening_balance_direction.dart';
import '../../../ledger/domain/entities/party.dart';
import '../../../ledger/domain/entities/party_type.dart';
import '../../../ledger/domain/repositories/party_repository.dart';
import '../../../ledger/presentation/providers/party_providers.dart';
import '../../../sales/presentation/providers/sale_providers.dart';
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
  final _partyQueryController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  Party? _selectedParty;
  DateTime _dateTime = DateTime.now();
  PaymentRegisterEntry? _existing;
  late PaymentFormMode _mode = widget.mode;
  bool _initialized = false;
  bool _isSaving = false;
  bool _isDeleting = false;

  bool get isReceived => _mode == PaymentFormMode.received;

  @override
  void dispose() {
    _partyQueryController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _applyEntry(PaymentRegisterEntry entry) {
    if (_initialized) return;
    _existing = entry;
    _mode = entry.isReceived ? PaymentFormMode.received : PaymentFormMode.paid;
    _dateTime = entry.createdAt;
    _amountController.text = _formatAmount(entry.amount);
    _noteController.text = entry.note ?? '';
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
    _partyQueryController.text = entry.partyName;
    _initialized = true;
  }

  Future<void> _loadInitialParty() async {
    if (_initialized || widget.initialPartyId == null) return;
    final result = await ref.read(getPartyUseCaseProvider)(widget.initialPartyId!);
    final party = result.valueOrNull;
    if (party != null && mounted) {
      setState(() {
        _selectedParty = party;
        _partyQueryController.text = party.name;
      });
    }
  }

  String _formatAmount(double value) {
    if (value == value.roundToDouble()) return value.round().toString();
    return value.toStringAsFixed(2);
  }

  void _selectParty(Party party) {
    setState(() {
      _selectedParty = party;
      _partyQueryController.text = party.name;
    });
  }

  void _clearParty() {
    setState(() {
      _selectedParty = null;
      _partyQueryController.clear();
    });
  }

  void _setQuickAmount(int amount) {
    setState(() => _amountController.text = amount.toString());
  }

  Future<void> _createPartyFromQuery(String name) async {
    final result = await ref.read(savePartyUseCaseProvider)(
      SavePartyInput(
        name: name,
        type: PartyType.both,
        phone: '',
        address: '',
        openingAmount: 0,
        openingDirection: OpeningBalanceDirection.receivable,
        isActive: true,
      ),
    );
    if (result.isFailure) {
      _showMessage(result.failureOrNull!.message);
      return;
    }
    notifyDataChanged(ref);
    _selectParty(result.valueOrNull!);
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
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Rahne dein')),
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
      final result = await ref.read(deletePaymentProvider)(id);
      if (result.isFailure) {
        _showMessage(result.failureOrNull!.message);
        return;
      }
      notifyDataChanged(ref);
      ref.invalidate(paymentListProvider);
      if (mounted) context.go(RouteNames.payments);
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
            message: error.toString(),
            actionLabel: 'Wapas',
            onAction: () => context.pop(),
          ),
        ),
        data: (entry) {
          if (entry == null) {
            return Scaffold(
              body: AppErrorView(
                title: 'Entry nahi mili',
                message: 'Yeh payment ab available nahi hai.',
                actionLabel: 'Wapas',
                onAction: () => context.pop(),
              ),
            );
          }
          _applyEntry(entry);
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
    final partyQuery = _partyQueryController.text;
    final partiesAsync = ref.watch(salePartySearchProvider(partyQuery));
    final title = widget.isEdit
        ? (isReceived ? 'Jama Badlo' : 'Payment Badlo')
        : (isReceived ? 'Jama Lo' : 'Paise Do');
    final saveLabel = isReceived ? 'Jama Save Karein' : 'Paise Do Save Karein';

    return Scaffold(
      backgroundColor: ColorPalette.background,
      appBar: AppBar(
        backgroundColor: ColorPalette.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
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
                    _SectionCard(
                      title: 'Party',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            controller: _partyQueryController,
                            onChanged: (_) {
                              if (_selectedParty != null &&
                                  _partyQueryController.text.trim() !=
                                      _selectedParty!.name) {
                                _selectedParty = null;
                              }
                              setState(() {});
                            },
                            decoration: InputDecoration(
                              hintText: 'Party chuniye',
                              filled: true,
                              fillColor: ColorPalette.background,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              suffixIcon: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_selectedParty != null || partyQuery.isNotEmpty)
                                    IconButton(
                                      icon: const Icon(Icons.close_rounded, size: 20),
                                      onPressed: _clearParty,
                                    ),
                                  IconButton(
                                    icon: const Icon(Icons.mic_none_rounded, size: 22),
                                    onPressed: () {},
                                    tooltip: 'Awaz se likhein (jald)',
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (_selectedParty == null && partyQuery.trim().isNotEmpty)
                            partiesAsync.when(
                              loading: () => const SizedBox.shrink(),
                              error: (_, _) => const SizedBox.shrink(),
                              data: (parties) {
                                if (parties.isEmpty) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: TextButton(
                                      onPressed: () =>
                                          _createPartyFromQuery(partyQuery.trim()),
                                      child: Text('"$partyQuery" jodein · Naya party'),
                                    ),
                                  );
                                }
                                return Column(
                                  children: parties.take(4).map((party) {
                                    return ListTile(
                                      dense: true,
                                      contentPadding: EdgeInsets.zero,
                                      title: Text(party.name),
                                      subtitle:
                                          party.phone.isEmpty ? null : Text(party.phone),
                                      onTap: () => _selectParty(party),
                                    );
                                  }).toList(),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _SectionCard(
                      title: 'Rashi',
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
                              fillColor: Color(0xFFF5F5F7),
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
                    _SectionCard(
                      title: 'Tareekh · Samay',
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
                    _SectionCard(
                      title: 'Note',
                      child: AppTextField(
                        controller: _noteController,
                        label: 'Note (optional)',
                        maxLines: 2,
                      ),
                    ),
                    if (widget.isEdit) ...[
                      const SizedBox(height: 16),
                      TextButton.icon(
                        onPressed: _isDeleting ? null : _handleDelete,
                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                        label: Text(
                          isReceived ? 'Jama Delete Karein' : 'Payment Delete Karein',
                          style: const TextStyle(color: Colors.red),
                        ),
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
                  label: saveLabel,
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

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
