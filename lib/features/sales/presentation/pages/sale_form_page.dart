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
import '../../../items/domain/entities/item.dart';
import '../../../items/presentation/widgets/entry_item_picker_sheet.dart';
import '../../../ledger/presentation/providers/party_providers.dart';
import '../../domain/entities/sale_entry.dart';
import '../../domain/repositories/sale_repository.dart';
import '../providers/sale_providers.dart';
import '../widgets/entry_party_picker_sheet.dart';

enum SaleFormMode { create, edit }

class DraftSaleLine {
  DraftSaleLine({
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

/// Record a sale — like writing in a register. Stock and ledger update automatically.
class SaleFormPage extends ConsumerStatefulWidget {
  const SaleFormPage({
    super.key,
    required this.mode,
    this.saleId,
    this.initialPartyId,
  });

  final SaleFormMode mode;
  final String? saleId;
  final String? initialPartyId;

  bool get isEdit => mode == SaleFormMode.edit;

  @override
  ConsumerState<SaleFormPage> createState() => _SaleFormPageState();
}

class _SaleFormPageState extends ConsumerState<SaleFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();

  Party? _selectedParty;
  DateTime _date = DateTime.now();
  PaymentMode _paymentMode = PaymentMode.cash;
  GstType _gstType = GstType.intra;
  final List<DraftSaleLine> _lines = [];
  SaleEntry? _existing;
  bool _initialized = false;
  bool _isSaving = false;
  bool _isDeleting = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _applyEntry(SaleEntry entry) {
    if (_initialized) return;
    _existing = entry;
    _date = entry.date;
    _paymentMode = entry.paymentMode;
    _gstType = entry.gstType;
    _notesController.text = entry.notes ?? '';
    _lines
      ..clear()
      ..addAll(
        entry.lines.map(
          (line) => DraftSaleLine(
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

  SaveSaleInput _buildInput() {
    return SaveSaleInput(
      id: _existing?.id,
      entryNo: _existing?.entryNo,
      date: _date,
      partyId: _selectedParty!.id,
      paymentMode: _paymentMode,
      gstType: _gstType,
      notes: _notesController.text,
      existingCreatedAt: _existing?.createdAt,
      lines: _lines
          .map(
            (line) => SaleLineInput(
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
    final item = await showModalBottomSheet<Item>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const EntryItemPickerSheet(
        mode: EntryItemMode.sale,
      ),
    );
    if (item == null) return;

    setState(() {
      _lines.add(
        DraftSaleLine(
          itemId: item.id,
          itemName: item.name,
          hsnSac: item.hsnSac,
          rate: item.saleRate,
          gstRate: item.gstRate,
        ),
      );
    });
  }

  Future<void> _handleSave() async {
    if (_selectedParty == null) {
      _showMessage('Pehle grahak chuniye');
      return;
    }
    if (_lines.isEmpty) {
      _showMessage('Add at least one item');
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final result = await ref.read(saveSaleUseCaseProvider)(_buildInput());
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
        title: const Text('Delete this sale?'),
        content: const Text('Yeh entry delete ho jayegi aur stock wapas aa jayega.'),
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
      final result = await ref.read(deleteSaleUseCaseProvider)(id);
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
    if (widget.isEdit && widget.saleId != null) {
      final saleAsync = ref.watch(saleDetailProvider(widget.saleId!));
      return saleAsync.when(
        loading: () => const Scaffold(body: AppLoadingView()),
        error: (error, _) => Scaffold(
          body: AppErrorView(
            title: 'Sale load nahi ho payi',
            message: error.toString(),
            actionLabel: 'Back',
            onAction: () => context.pop(),
          ),
        ),
        data: (entry) {
          if (entry == null) {
            return Scaffold(
              body: AppErrorView(
                title: 'Sale not found',
                message: 'Yeh entry ab available nahi hai.',
                actionLabel: 'Back',
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
    final totals = _computedAmounts.isEmpty
        ? null
        : GstCalculator.aggregate(_computedAmounts);

    return Scaffold(
      backgroundColor: ColorPalette.background,
      appBar: AppBar(
        backgroundColor: ColorPalette.background,
        elevation: 0,
        title: BilingualLabel(
          english: widget.isEdit ? 'Edit Sale' : 'Record Sale',
          hindi: widget.isEdit ? 'Sale badlo' : 'Sale likho',
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
                            english: 'Money received?',
                            hindi: 'Paisa abhi mila ya udhaar?',
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
                      title: 'What sold · Kya becha',
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
                      title: 'Note (optional)',
                      child: AppTextField(
                        controller: _notesController,
                        label: 'Kuch yaad rakhna ho to likhein',
                        maxLines: 2,
                      ),
                    ),
                    const SizedBox(height: 24),
                    AppPrimaryButton(
                      label: widget.isEdit ? 'Save · Save karein' : 'Record Sale · Sale likho',
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

  final DraftSaleLine line;
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
