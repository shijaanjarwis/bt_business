import 'package:bt_business/core/errors/user_error_messages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/item_unit_library.dart';
import '../../../../core/accounting/gst_types.dart';
import '../../../../core/accounting/payment_breakdown.dart';
import '../../../../core/accounting/payment_method_channel.dart';
import '../../../../core/accounting/payment_modes.dart';
import '../../../../core/di/data_revision.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/gst_calculator.dart';
import '../../../../core/utils/rate_field_utils.dart';
import '../../../../shared/widgets/branding/developer_footer.dart';
import '../../../../shared/widgets/buttons/app_primary_button.dart';
import '../../../../shared/widgets/dialogs/confirmation_dialog.dart';
import '../../../../shared/widgets/feedback/app_error_view.dart';
import '../../../../shared/widgets/feedback/app_loading_view.dart';
import '../../../../shared/widgets/inputs/app_party_picker_field.dart';
import '../../../../shared/widgets/inputs/app_picker_field.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';
import '../../../../shared/widgets/inputs/editable_quantity_input.dart';
import '../../../../shared/widgets/inputs/entry_rate_field.dart';
import '../../../../shared/widgets/inputs/payment_breakdown_fields.dart';
import '../../../../shared/widgets/inputs/reminder_date_field.dart';
import '../../../../shared/widgets/layout/app_form_section.dart';
import '../../../../shared/widgets/layout/main_shell_insets.dart';
import '../../../../shared/widgets/pickers/show_item_picker.dart';
import '../../../../shared/widgets/scaffold/app_register_app_bar.dart';
import '../../../items/presentation/providers/item_providers.dart';
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
    this.unit = ItemUnitLibrary.defaultUnit,
    this.qty = 1,
    this.rate = 0,
    this.discountAmount = 0,
    this.gstRate = 0,
  });

  final String itemId;
  final String itemName;
  final String? hsnSac;
  String unit;
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
  final _cashController = TextEditingController();
  final _upiController = TextEditingController();
  final _bankController = TextEditingController();

  Party? _selectedParty;
  DateTime _date = DateTime.now();
  GstType _gstType = GstType.intra;
  final List<DraftPurchaseLine> _lines = [];
  PurchaseInvoice? _existing;
  bool _initialized = false;
  bool _editHydrated = false;
  bool _isSaving = false;
  bool _isDeleting = false;
  bool _paymentManuallyEdited = false;
  String? _defaultPartyId;
  DateTime? _reminderDate;
  PaymentMethodChannel _selectedPaymentMethod = PaymentMethodChannel.cash;

  @override
  void dispose() {
    _notesController.dispose();
    _cashController.dispose();
    _upiController.dispose();
    _bankController.dispose();
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
    final breakdown = invoice.paymentBreakdown;
    _cashController.text = _formatAmount(breakdown.cash);
    _upiController.text = _formatAmount(breakdown.upi);
    _bankController.text = _formatAmount(breakdown.bank);
    _selectedPaymentMethod = PaymentMethodChannel.fromBreakdown(breakdown);
    _paymentManuallyEdited = true;
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
    _enrichLineUnits();
  }

  Future<void> _enrichLineUnits() async {
    final repo = ref.read(itemRepositoryProvider);
    var changed = false;
    for (final line in _lines) {
      final result = await repo.getItem(line.itemId);
      final item = result.valueOrNull;
      if (item != null && item.unit != line.unit) {
        line.unit = item.unit;
        changed = true;
      }
    }
    if (changed && mounted) setState(() {});
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

  PaymentBreakdown get _paymentBreakdown => PaymentBreakdown(
        cash: _parseAmount(_cashController),
        upi: _parseAmount(_upiController),
        bank: _parseAmount(_bankController),
      );

  double get _paidAmount => _paymentBreakdown.paidTotal;

  double get _dueAmount =>
      _paymentBreakdown.remainingCredit(_grandTotal);

  void _syncPaymentWithTotal() {
    if (_paymentManuallyEdited || widget.isEdit) return;
    _cashController.text = _formatAmount(_grandTotal);
    _upiController.text = '0';
    _bankController.text = '0';
    _selectedPaymentMethod = PaymentMethodChannel.cash;
  }

  void _selectPaymentMethod(PaymentMethodChannel method) {
    setState(() {
      _selectedPaymentMethod = method;
      final paid = _paidAmount > 0 ? _paidAmount : _grandTotal;
      if (paid > 0) {
        _cashController.text =
            method == PaymentMethodChannel.cash ? _formatAmount(paid) : '0';
        _upiController.text =
            method == PaymentMethodChannel.upi ? _formatAmount(paid) : '0';
        _bankController.text =
            method == PaymentMethodChannel.bank ? _formatAmount(paid) : '0';
      }
      _paymentManuallyEdited = true;
      if (_dueAmount <= 0) _reminderDate = null;
    });
  }

  double _parseAmount(TextEditingController controller) =>
      double.tryParse(controller.text.trim()) ?? 0;

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
      paymentMode: _dueAmount > 0 ? PaymentMode.credit : PaymentMode.cash,
      paymentBreakdown: _paymentBreakdown.clampToTotal(_grandTotal),
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
            unit: item.unit,
            rate: item.purchaseRate,
            gstRate: item.gstRate,
          ),
        );
      }
      _syncPaymentWithTotal();
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

    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Yeh kharid delete karein?',
      message: 'Yeh entry delete ho jayegi.',
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
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              20,
              0,
              20,
              MainShellInsets.scrollBottom(context),
            ),
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
                            setState(_syncPaymentWithTotal);
                          },
                          onRemove: () {
                            setState(() {
                              _lines.removeAt(entry.key);
                              _syncPaymentWithTotal();
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
                english: 'Payment Breakdown',
                hindi: 'Payment Hisaab',
                child: PaymentBreakdownFields(
                  grandTotal: _grandTotal,
                  totalLabel: 'Total Amount',
                  creditLabel: 'Credit (Remaining)',
                  cashController: _cashController,
                  upiController: _upiController,
                  bankController: _bankController,
                  selectedMethod: _selectedPaymentMethod,
                  onMethodSelected: _selectPaymentMethod,
                  onChanged: ({required cash, required upi, required bank}) {
                    setState(() {
                      _paymentManuallyEdited = true;
                      _selectedPaymentMethod = PaymentMethodChannel.fromBreakdown(
                        PaymentBreakdown(cash: cash, upi: upi, bank: bank),
                      );
                      if (_dueAmount <= 0) _reminderDate = null;
                    });
                  },
                ),
              ),
              if (_dueAmount > 0) ...[
                const SizedBox(height: 12),
                AppFormSection(
                  english: 'Reminder',
                  hindi: 'Reminder',
                  child: ReminderDateField(
                    reminderDate: _reminderDate,
                    onChanged: (date) => setState(() => _reminderDate = date),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              AppFormSection(
                english: 'Notes',
                hindi: 'Note',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Date',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        DateFormatter.shortDate(_date),
                        style: const TextStyle(
                          color: ColorPalette.labelSecondary,
                          fontWeight: FontWeight.w600,
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
              const SizedBox(height: 20),
              AppPrimaryButton(
                english: 'Save',
                hindi: 'Save Karein',
                isLoading: _isSaving,
                onPressed: _handleSave,
              ),
              if (widget.isEdit) ...[
                const SizedBox(height: 12),
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
  late final _rateController = TextEditingController(
    text: RateFieldUtils.initialText(widget.line.rate),
  );

  @override
  void dispose() {
    _rateController.dispose();
    super.dispose();
  }

  void _syncRate() {
    widget.line.rate = RateFieldUtils.parse(_rateController.text);
    widget.onChanged();
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
              EditableQuantityInput(
                value: widget.line.qty,
                unit: widget.line.unit,
                onChanged: (qty) {
                  setState(() {
                    widget.line.qty = qty;
                    widget.onChanged();
                  });
                },
              ),
              const SizedBox(width: 12),
              Expanded(
                child: EntryRateField(
                  controller: _rateController,
                  onChanged: _syncRate,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
