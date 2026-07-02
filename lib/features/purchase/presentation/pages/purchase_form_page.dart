import 'package:bt_business/core/errors/user_error_messages.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/accounting/gst_types.dart';
import '../../../../core/accounting/payment_modes.dart';
import '../../../../core/di/data_revision.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/gst_calculator.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/branding/developer_footer.dart';
import '../../../../shared/widgets/buttons/app_primary_button.dart';
import '../../../../shared/widgets/feedback/app_error_view.dart';
import '../../../../shared/widgets/feedback/app_loading_view.dart';
import '../../../../shared/widgets/inputs/app_party_picker_field.dart';
import '../../../../shared/widgets/inputs/app_picker_field.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';
import '../../../../shared/widgets/inputs/reminder_date_field.dart';
import '../../../../shared/widgets/labels/bilingual_label.dart';
import '../../../../shared/widgets/layout/app_form_section.dart';
import '../../../../shared/widgets/pickers/show_item_picker.dart';
import '../../../../shared/widgets/scaffold/app_register_app_bar.dart';
import '../../../items/presentation/widgets/entry_item_picker_sheet.dart';
import '../../../items/domain/entities/item.dart';
import '../../../ledger/domain/entities/party.dart';
import '../../../ledger/domain/entities/party_type.dart';
import '../../../ledger/presentation/providers/party_providers.dart';
import '../../../sales/presentation/providers/sale_providers.dart';
import '../../domain/entities/purchase_invoice.dart';
import '../../domain/repositories/purchase_repository.dart';
import '../providers/purchase_providers.dart';
import '../utils/purchase_ui_helpers.dart';

enum PurchaseFormMode { create, edit }

class DraftPurchaseLine {
  DraftPurchaseLine({
    required this.itemId,
    required this.itemName,
    this.hsnSac,
    this.qty = 1,
    this.rate = 0,
    this.discountAmount = 0,
    this.gstRate = 0,
  });

  final String itemId;
  final String itemName;
  final String? hsnSac;
  double qty;
  double rate;
  double discountAmount;
  double gstRate;
}

/// Fast purchase entry — same flow as Bikri Likho.
class PurchaseFormPage extends ConsumerStatefulWidget {
  const PurchaseFormPage({
    super.key,
    required this.mode,
    this.purchaseId,
    this.initialPartyId,
  });

  final PurchaseFormMode mode;
  final String? purchaseId;
  final String? initialPartyId;

  bool get isEdit => mode == PurchaseFormMode.edit;

  @override
  ConsumerState<PurchaseFormPage> createState() => _PurchaseFormPageState();
}

class _PurchaseFormPageState extends ConsumerState<PurchaseFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final _paidController = TextEditingController();

  Party? _selectedParty;
  DateTime _date = DateTime.now();
  GstType _gstType = GstType.intra;
  final List<DraftPurchaseLine> _lines = [];
  PurchaseInvoice? _existing;
  bool _initialized = false;
  bool _editHydrated = false;
  bool _isSaving = false;
  bool _isDeleting = false;
  bool _paidManuallyEdited = false;
  String? _defaultPartyId;
  double? _lastAutoPaidTotal;
  DateTime? _reminderDate;

  @override
  void dispose() {
    _notesController.dispose();
    _paidController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant PurchaseFormPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.purchaseId != widget.purchaseId) {
      _editHydrated = false;
      _existing = null;
    }
  }

  void _applyInvoice(PurchaseInvoice invoice, String? defaultPartyId) {
    if (_editHydrated) return;
    _existing = invoice;
    _date = invoice.date;
    _gstType = invoice.gstType;
    _notesController.text = invoice.notes ?? '';
    _paidController.text = _formatAmount(invoice.paidAmount);
    _paidManuallyEdited = true;
    _defaultPartyId = defaultPartyId;
    _reminderDate = invoice.reminderDate;

    if (!PurchaseUiHelpers.isDefaultCashParty(
      partyId: invoice.partyId,
      partyName: invoice.partyName,
      defaultPartyId: defaultPartyId,
    )) {
      _selectedParty = Party(
        id: invoice.partyId,
        businessId: invoice.businessId,
        name: invoice.partyName,
        type: PartyType.both,
        phone: '',
        address: '',
        openingBalance: 0,
        balance: 0,
        isActive: true,
        createdAt: invoice.createdAt,
        updatedAt: invoice.updatedAt,
      );
    }

    _lines
      ..clear()
      ..addAll(
        invoice.lines.map(
          (line) => DraftPurchaseLine(
            itemId: line.itemId,
            itemName: line.itemName,
            hsnSac: line.hsnSac,
            qty: line.qty,
            rate: line.rate,
            discountAmount: line.discountAmount,
            gstRate: line.gstRate,
          ),
        ),
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

  List<SaleLineAmounts> get _computedAmounts => _lines
      .map(
        (line) => GstCalculator.computeLine(
          qty: line.qty,
          rate: line.rate,
          discountAmount: line.discountAmount,
          gstRate: line.gstRate,
          gstType: _gstType,
        ),
      )
      .toList();

  double get _grandTotal {
    if (_computedAmounts.isEmpty) return 0;
    return GstCalculator.aggregate(_computedAmounts).grandTotal;
  }

  double get _paidAmount {
    final parsed = double.tryParse(_paidController.text.trim());
    if (parsed != null) return parsed;
    return _paidManuallyEdited ? 0 : _grandTotal;
  }

  double get _dueAmount => (_grandTotal - _paidAmount).clamp(0, double.infinity);

  void _syncPaidWithTotal() {
    if (_paidManuallyEdited || widget.isEdit) return;
    if (_lastAutoPaidTotal == _grandTotal) return;
    _lastAutoPaidTotal = _grandTotal;
    _paidController.text = _formatAmount(_grandTotal);
  }

  String _formatAmount(double value) {
    if (value == value.roundToDouble()) {
      return value.round().toString();
    }
    return value.toStringAsFixed(2);
  }

  SavePurchaseInput _buildInput(String partyId) {
    return SavePurchaseInput(
      id: _existing?.id,
      invoiceNo: _existing?.invoiceNo,
      date: _date,
      partyId: partyId,
      paymentMode: PaymentMode.cash,
      paidAmount: _paidAmount,
      gstType: _gstType,
      notes: _notesController.text.trim(),
      existingCreatedAt: _existing?.createdAt,
      reminderDate: _dueAmount > 0 ? _reminderDate : null,
      lines: _lines
          .map(
            (line) => PurchaseLineInput(
              itemId: line.itemId,
              itemName: line.itemName,
              hsnSac: line.hsnSac,
              qty: line.qty,
              rate: line.rate,
              discountAmount: line.discountAmount,
              gstRate: line.gstRate,
            ),
          )
          .toList(),
    );
  }

  void _addItemFromPicker(Item item) {
    final existingLineIndex = _lines.indexWhere((line) => line.itemId == item.id);
    setState(() {
      if (existingLineIndex >= 0) {
        _lines[existingLineIndex].qty += 1;
      } else {
        _lines.add(
          DraftPurchaseLine(
            itemId: item.id,
            itemName: item.name,
            hsnSac: item.hsnSac,
            rate: item.purchaseRate,
            gstRate: item.gstRate,
          ),
        );
      }
      _syncPaidWithTotal();
    });
  }

  Future<void> _pickItem() async {
    final item = await showItemPicker(context, ref, mode: EntryItemMode.purchase);
    if (item != null && mounted) {
      _addItemFromPicker(item);
    }
  }

  Future<void> _handleSave() async {
    if (_lines.isEmpty) {
      _showMessage('Pehle maal jodein');
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    if (_paidAmount < 0 || _paidAmount > _grandTotal) {
      _showMessage('Sahi rashi likhein — total se zyada nahi');
      return;
    }

    final defaultPartyId =
        _defaultPartyId ?? await ref.read(cashCustomerPartyIdProvider.future);
    final partyId = _selectedParty?.id ?? defaultPartyId;
    if (partyId == null) {
      _showMessage('Business setup complete karein');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final result = await ref.read(savePurchaseUseCaseProvider)(_buildInput(partyId));
      if (result.isFailure) {
        _showMessage(result.failureOrNull!.message);
        return;
      }
      notifyDataChanged(ref);
      ref.invalidate(purchaseListProvider);
      if (!mounted) return;
      if (widget.isEdit) {
        context.pop();
      } else {
        context.go(RouteNames.purchases);
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
        title: const Text('Yeh kharid delete karein?'),
        content: const Text('Yeh entry delete ho jayegi.'),
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
      final result = await ref.read(deletePurchaseUseCaseProvider)(id);
      if (result.isFailure) {
        _showMessage(result.failureOrNull!.message);
        return;
      }
      notifyDataChanged(ref);
      ref.invalidate(purchaseListProvider);
      if (mounted) context.go(RouteNames.purchases);
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final defaultPartyAsync = ref.watch(cashCustomerPartyIdProvider);
    _defaultPartyId = defaultPartyAsync.valueOrNull;

    if (widget.isEdit && widget.purchaseId != null) {
      final purchaseAsync = ref.watch(purchaseDetailProvider(widget.purchaseId!));
      return purchaseAsync.when(
        loading: () => const Scaffold(body: AppLoadingView()),
        error: (error, _) => Scaffold(
          body: AppErrorView(
            title: 'Kharid load nahi ho payi',
            message: UserErrorMessages.from(error),
            actionEnglish: 'Back', actionHindi: 'Wapas',
            onAction: () => context.pop(),
          ),
        ),
        data: (invoice) {
          if (invoice == null) {
            return Scaffold(
              body: AppErrorView(
                title: 'Kharid nahi mili',
                message: 'Yeh entry ab available nahi hai.',
                actionEnglish: 'Back', actionHindi: 'Wapas',
                onAction: () => context.pop(),
              ),
            );
          }
          if (!defaultPartyAsync.hasValue) {
            return const Scaffold(body: AppLoadingView());
          }
          if (!_editHydrated) {
            _applyInvoice(invoice, defaultPartyAsync.value);
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
    return Scaffold(
      backgroundColor: ColorPalette.background,
      appBar: AppRegisterAppBar(
        english: widget.isEdit ? 'Edit Purchase' : 'Purchase',
        hindi: widget.isEdit ? 'Kharid Badlo' : 'Maal Kharida',
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
                      helper: 'Khali chhodein to cash kharid',
                      allowClear: true,
                    ),
                    if (_selectedParty == null)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          'Cash Kharid',
                          style: TextStyle(
                            color: ColorPalette.purple,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    AppFormSection(
                      english: 'Goods',
                      hindi: 'Maal',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AppPickerField(
                            english: 'Add Item',
                            hindi: 'Maal Jodein',
                            value: null,
                            onTap: _pickItem,
                            emptyText: 'Add item to purchase',
                            emptyHindi: 'Maal jodein',
                            trailingIcon: Icons.add_circle_outline_rounded,
                          ),
                          if (_lines.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            ..._lines.asMap().entries.map((entry) {
                              return _LineCard(
                                line: entry.value,
                                onChanged: () {
                                  setState(_syncPaidWithTotal);
                                },
                                onRemove: () {
                                  setState(() {
                                    _lines.removeAt(entry.key);
                                    _syncPaidWithTotal();
                                  });
                                },
                              );
                            }),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    AppFormSection(
                      english: 'Date and Note',
                      hindi: 'Tareekh aur Note',
                      child: Column(
                        children: [
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text(
                              'Date',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              '(${DateFormatter.shortDate(_date)})',
                              style: const TextStyle(
                                color: ColorPalette.labelSecondary,
                              ),
                            ),
                            trailing: const Icon(
                              Icons.calendar_today_rounded,
                              size: 20,
                              color: ColorPalette.iconPrimary,
                            ),
                            onTap: _pickDate,
                          ),
                          AppTextField(
                            english: 'Note',
                            hindi: 'Note',
                            controller: _notesController,
                            helper: 'Optional',
                            maxLines: 2,
                          ),
                        ],
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
              _PaymentSummaryBar(
                grandTotal: _grandTotal,
                paidController: _paidController,
                dueAmount: _dueAmount,
                reminderDate: _reminderDate,
                onReminderChanged: (date) => setState(() => _reminderDate = date),
                onPaidChanged: (value) {
                  setState(() {
                    _paidManuallyEdited = true;
                    _paidController.text = value;
                    if (_dueAmount <= 0) _reminderDate = null;
                  });
                },
                isSaving: _isSaving,
                onSave: _handleSave,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LineCard extends StatefulWidget {
  const _LineCard({
    required this.line,
    required this.onChanged,
    required this.onRemove,
  });

  final DraftPurchaseLine line;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  @override
  State<_LineCard> createState() => _LineCardState();
}

class _LineCardState extends State<_LineCard> {
  late final _rateController =
      TextEditingController(text: widget.line.rate.toString());

  @override
  void dispose() {
    _rateController.dispose();
    super.dispose();
  }

  void _syncRate() {
    widget.line.rate = double.tryParse(_rateController.text) ?? widget.line.rate;
    widget.onChanged();
  }

  void _changeQty(double delta) {
    final next = (widget.line.qty + delta).clamp(0.001, 999999.0).toDouble();
    setState(() {
      widget.line.qty = next;
      widget.onChanged();
    });
  }

  double get _lineTotal => widget.line.qty * widget.line.rate;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ColorPalette.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.line.itemName,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                CurrencyFormatter.format(_lineTotal),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: ColorPalette.purple,
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: widget.onRemove,
                icon: const Icon(Icons.close_rounded, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _QtyButton(icon: Icons.remove_rounded, onTap: () => _changeQty(-1)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  widget.line.qty == widget.line.qty.roundToDouble()
                      ? widget.line.qty.round().toString()
                      : widget.line.qty.toStringAsFixed(2),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
              _QtyButton(icon: Icons.add_rounded, onTap: () => _changeQty(1)),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _rateController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Rate · Daam',
                    isDense: true,
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (v) => Validators.positiveAmount(v),
                  onChanged: (_) => _syncRate(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  const _QtyButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, size: 20, color: ColorPalette.purple),
        ),
      ),
    );
  }
}

class _PaymentSummaryBar extends StatelessWidget {
  const _PaymentSummaryBar({
    required this.grandTotal,
    required this.paidController,
    required this.dueAmount,
    required this.reminderDate,
    required this.onReminderChanged,
    required this.onPaidChanged,
    required this.isSaving,
    required this.onSave,
  });

  final double grandTotal;
  final TextEditingController paidController;
  final double dueAmount;
  final DateTime? reminderDate;
  final ValueChanged<DateTime?> onReminderChanged;
  final ValueChanged<String> onPaidChanged;
  final bool isSaving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        16 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SummaryRow(
            label: 'Kul Kharid',
            value: CurrencyFormatter.format(grandTotal),
            emphasized: true,
          ),
          const Divider(height: 20),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Aaj Kitna Diya',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              SizedBox(
                width: 120,
                child: TextFormField(
                  controller: paidController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textAlign: TextAlign.right,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  decoration: const InputDecoration(
                    prefixText: '₹ ',
                    isDense: true,
                    filled: true,
                    fillColor: ColorPalette.fieldFill,
                    border: OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                  ),
                  onChanged: onPaidChanged,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _SummaryRow(
            label: 'Baaki',
            value: CurrencyFormatter.format(dueAmount),
            valueColor: dueAmount > 0 ? Colors.orange.shade800 : ColorPalette.labelSecondary,
          ),
          if (dueAmount > 0) ...[
            const SizedBox(height: 8),
            ReminderDateField(
              reminderDate: reminderDate,
              onChanged: onReminderChanged,
            ),
          ],
          const SizedBox(height: 16),
          AppPrimaryButton(
            english: 'Save',
            hindi: 'Save Karein',
            isLoading: isSaving,
            onPressed: onSave,
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.emphasized = false,
    this.valueColor,
  });

  final String label;
  final String value;
  final bool emphasized;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: emphasized ? FontWeight.w700 : FontWeight.w600,
              fontSize: emphasized ? 16 : 14,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: emphasized ? 18 : 15,
            color: valueColor ?? ColorPalette.purple,
          ),
        ),
      ],
    );
  }
}
