import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/accounting/gst_types.dart';
import '../../../../core/accounting/payment_modes.dart';
import '../../../../core/di/data_revision.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/gst_calculator.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/buttons/app_primary_button.dart';
import '../../../../shared/widgets/feedback/app_error_view.dart';
import '../../../../shared/widgets/feedback/app_loading_view.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';
import '../../../../shared/widgets/layout/app_form_section.dart';
import '../../../../shared/widgets/layout/responsive_form_container.dart';
import '../../../../shared/widgets/labels/bilingual_label.dart';
import '../../../ledger/domain/entities/party.dart';
import '../../../ledger/presentation/providers/party_providers.dart';
import '../../../items/presentation/widgets/entry_item_picker_sheet.dart';
import '../../../sales/presentation/widgets/entry_party_picker_sheet.dart';
import '../../../../features/sales/data/models/sale_item_model.dart';
import '../../domain/entities/purchase_invoice.dart';
import '../../domain/repositories/purchase_repository.dart';
import '../providers/purchase_providers.dart';

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

/// Record a purchase — like writing in a register. Stock and ledger update automatically.
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

  Party? _selectedParty;
  DateTime _date = DateTime.now();
  PaymentMode _paymentMode = PaymentMode.cash;
  GstType _gstType = GstType.intra;
  final List<DraftPurchaseLine> _lines = [];
  PurchaseInvoice? _existing;
  bool _initialized = false;
  bool _isSaving = false;
  bool _isDeleting = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _applyInvoice(PurchaseInvoice invoice) {
    if (_initialized) return;
    _existing = invoice;
    _date = invoice.date;
    _paymentMode = invoice.paymentMode;
    _gstType = invoice.gstType;
    _notesController.text = invoice.notes ?? '';
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
    _initialized = true;
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

  SavePurchaseInput _buildInput() {
    return SavePurchaseInput(
      id: _existing?.id,
      invoiceNo: _existing?.invoiceNo,
      date: _date,
      partyId: _selectedParty!.id,
      paymentMode: _paymentMode,
      gstType: _gstType,
      notes: _notesController.text,
      existingCreatedAt: _existing?.createdAt,
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

  Future<void> _pickParty() async {
    final party = await showModalBottomSheet<Party>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const EntryPartyPickerSheet(),
    );
    if (party != null) setState(() => _selectedParty = party);
  }

  Future<void> _addLine() async {
    final item = await showModalBottomSheet<SaleItem>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const EntryItemPickerSheet(
        mode: EntryItemMode.purchase,
      ),
    );
    if (item == null) return;

    setState(() {
      _lines.add(
        DraftPurchaseLine(
          itemId: item.id,
          itemName: item.name,
          hsnSac: item.hsnSac,
          rate: item.purchaseRate,
          gstRate: item.gstRate,
        ),
      );
    });
  }

  Future<void> _handleSave() async {
    if (_selectedParty == null) {
      _showMessage('Party chuniye');
      return;
    }
    if (_lines.isEmpty) {
      _showMessage('Add at least one item');
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final result = await ref.read(savePurchaseUseCaseProvider)(_buildInput());
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
    final id = _existing?.id;
    if (id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this purchase?'),
        content: const Text('Yeh entry delete ho jayegi aur stock adjust ho jayega.'),
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

    setState(() => _isDeleting = true);
    try {
      final result = await ref.read(deletePurchaseUseCaseProvider)(id);
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
    if (widget.isEdit && widget.purchaseId != null) {
      final purchaseAsync = ref.watch(purchaseDetailProvider(widget.purchaseId!));
      return purchaseAsync.when(
        loading: () => const Scaffold(body: AppLoadingView()),
        error: (error, _) => Scaffold(
          body: AppErrorView(
            title: 'Purchase load nahi ho payi',
            message: error.toString(),
            actionLabel: 'Back',
            onAction: () => context.pop(),
          ),
        ),
        data: (invoice) {
          if (invoice == null) {
            return Scaffold(
              body: AppErrorView(
                title: 'Purchase not found',
                message: 'Yeh entry ab available nahi hai.',
                actionLabel: 'Back',
                onAction: () => context.pop(),
              ),
            );
          }
          _applyInvoice(invoice);
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
    final totals = _computedAmounts.isEmpty
        ? null
        : GstCalculator.aggregate(_computedAmounts);

    return Scaffold(
      backgroundColor: ColorPalette.background,
      appBar: AppBar(
        backgroundColor: ColorPalette.background,
        elevation: 0,
        title: BilingualLabel(
          english: widget.isEdit ? 'Edit Purchase' : 'Record Purchase',
          hindi: widget.isEdit ? 'Kharid badlo' : 'Kharid likho',
          compact: true,
        ),
        actions: [
          if (widget.isEdit && _existing != null)
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
                    AppFormSection(
                      title: 'Who & When',
                      child: Column(
                        children: [
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Party · Naam'),
                            subtitle: Text(
                              _selectedParty?.name ?? 'Party chuniye',
                            ),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: _pickParty,
                          ),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Date · Tareekh'),
                            subtitle: Text(DateFormatter.shortDate(_date)),
                            trailing: const Icon(Icons.calendar_today_rounded),
                            onTap: _pickDate,
                          ),
                          const SizedBox(height: 8),
                          const BilingualLabel(
                            english: 'Paid how?',
                            hindi: 'Cash ya udhaar',
                            compact: true,
                          ),
                          Wrap(
                            spacing: 8,
                            children: PaymentMode.values.map((mode) {
                              return ChoiceChip(
                                label: Text('${mode.englishLabel} · ${mode.hindiLabel}'),
                                selected: _paymentMode == mode,
                                onSelected: (_) => setState(() => _paymentMode = mode),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    AppFormSection(
                      title: 'What bought · Kya khareeda',
                      child: Column(
                        children: [
                          ..._lines.asMap().entries.map((entry) {
                            final index = entry.key;
                            final line = entry.value;
                            return _LineEditor(
                              line: line,
                              onChanged: () => setState(() {}),
                              onRemove: () => setState(() => _lines.removeAt(index)),
                            );
                          }),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: _addLine,
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Add Item · Maal jodein'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (totals != null)
                      AppFormSection(
                        title: 'Total · Kul',
                        child: _TotalRow(
                          label: 'Amount · Raashi',
                          amount: totals.grandTotal,
                          bold: true,
                        ),
                      ),
                    const SizedBox(height: 12),
                    AppFormSection(
                      title: 'Notes',
                      child: AppTextField(
                        controller: _notesController,
                        label: 'Notes · Koi note (optional)',
                        maxLines: 2,
                      ),
                    ),
                    const SizedBox(height: 24),
                    AppPrimaryButton(
                      label: widget.isEdit ? 'Save · Save karein' : 'Record Purchase · Kharid likho',
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

class _TotalRow extends StatelessWidget {
  const _TotalRow({
    required this.label,
    required this.amount,
    this.bold = false,
  });

  final String label;
  final double amount;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          Text(
            CurrencyFormatter.format(amount),
            style: TextStyle(
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _LineEditor extends StatefulWidget {
  const _LineEditor({
    required this.line,
    required this.onChanged,
    required this.onRemove,
  });

  final DraftPurchaseLine line;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  @override
  State<_LineEditor> createState() => _LineEditorState();
}

class _LineEditorState extends State<_LineEditor> {
  late final _qtyController = TextEditingController(text: widget.line.qty.toString());
  late final _rateController = TextEditingController(text: widget.line.rate.toString());

  @override
  void dispose() {
    _qtyController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  void _sync() {
    widget.line.qty = double.tryParse(_qtyController.text) ?? widget.line.qty;
    widget.line.rate = double.tryParse(_rateController.text) ?? widget.line.rate;
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12),
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
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              IconButton(
                onPressed: widget.onRemove,
                icon: const Icon(Icons.close_rounded, size: 20),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _qtyController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Qty · Matra'),
                  validator: (v) => Validators.positiveAmount(v),
                  onChanged: (_) => _sync(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: _rateController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Rate · Daam'),
                  validator: (v) => Validators.positiveAmount(v),
                  onChanged: (_) => _sync(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
