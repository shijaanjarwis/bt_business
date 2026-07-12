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
import '../../domain/entities/sale_entry.dart';
import '../../../../shared/widgets/inputs/editable_quantity_input.dart';
import '../../../../shared/widgets/inputs/entry_rate_field.dart';
import '../../../../shared/widgets/inputs/payment_breakdown_fields.dart';
import '../../../../shared/widgets/inputs/reminder_date_field.dart';
import '../../domain/repositories/sale_repository.dart';
import '../providers/sale_providers.dart';
import '../utils/sale_ui_helpers.dart';

enum SaleFormMode { create, edit }

class DraftSaleLine {
  DraftSaleLine({
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

/// Fast sale entry — register style, Hindi first.
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
  final _cashController = TextEditingController();
  final _upiController = TextEditingController();
  final _bankController = TextEditingController();

  Party? _selectedParty;
  DateTime _date = DateTime.now();
  GstType _gstType = GstType.intra;
  final List<DraftSaleLine> _lines = [];
  SaleEntry? _existing;
  bool _initialized = false;
  bool _editHydrated = false;
  bool _isSaving = false;
  bool _isDeleting = false;
  String? _cashCustomerPartyId;
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
  void didUpdateWidget(covariant SaleFormPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.saleId != widget.saleId) {
      _editHydrated = false;
      _existing = null;
    }
  }

  void _applyEntry(SaleEntry entry, String? cashCustomerId) {
    if (_editHydrated) return;
    _existing = entry;
    _date = entry.date;
    _gstType = entry.gstType;
    _notesController.text = entry.notes ?? '';
    final breakdown = entry.paymentBreakdown;
    _cashController.text = _amountFieldText(breakdown.cash);
    _upiController.text = _amountFieldText(breakdown.upi);
    _bankController.text = _amountFieldText(breakdown.bank);
    _selectedPaymentMethod = PaymentMethodChannel.fromBreakdown(breakdown);
    _cashCustomerPartyId = cashCustomerId;
    _reminderDate = entry.reminderDate;

    if (!SaleUiHelpers.isCashCustomerParty(
      partyId: entry.partyId,
      partyName: entry.partyName,
      cashCustomerPartyId: cashCustomerId,
    )) {
      _selectedParty = Party(
        id: entry.partyId,
        businessId: entry.businessId,
        name: entry.partyName,
        type: PartyType.both,
        phone: '',
        address: '',
        openingBalance: 0,
        balance: 0,
        isActive: true,
        createdAt: entry.createdAt,
        updatedAt: entry.updatedAt,
      );
    }

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

  void _selectPaymentMethod(PaymentMethodChannel method) {
    setState(() {
      _selectedPaymentMethod = method;
      if (_dueAmount <= 0) _reminderDate = null;
    });
  }

  String _amountFieldText(double value) =>
      value > 0 ? _formatAmount(value) : '';

  double _parseAmount(TextEditingController controller) =>
      double.tryParse(controller.text.trim()) ?? 0;

  String _formatAmount(double value) {
    if (value == value.roundToDouble()) {
      return value.round().toString();
    }
    return value.toStringAsFixed(2);
  }

  SaveSaleInput _buildInput(String partyId) {
    return SaveSaleInput(
      id: _existing?.id,
      entryNo: _existing?.entryNo,
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

  void _addItemFromPicker(Item item) {
    final existingLineIndex = _lines.indexWhere((line) => line.itemId == item.id);
    setState(() {
      if (existingLineIndex >= 0) {
        _lines[existingLineIndex].qty += 1;
      } else {
        _lines.add(
          DraftSaleLine(
            itemId: item.id,
            itemName: item.name,
            hsnSac: item.hsnSac,
            unit: item.unit,
            rate: item.saleRate,
            gstRate: item.gstRate,
          ),
        );
      }
    });
  }

  Future<void> _pickItem() async {
    final item = await showItemPicker(context, ref, mode: EntryItemMode.sale);
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

    final cashCustomerId = _cashCustomerPartyId ??
        await ref.read(cashCustomerPartyIdProvider.future);
    final partyId = _selectedParty?.id ?? cashCustomerId;
    if (partyId == null) {
      _showMessage('Business setup complete karein');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final result = await ref.read(saveSaleUseCaseProvider)(_buildInput(partyId));
      if (result.isFailure) {
        _showMessage(result.failureOrNull!.message);
        return;
      }
      notifyDataChanged(ref);
      ref.invalidate(saleListProvider);
      if (!mounted) return;
      if (widget.isEdit) {
        context.pop();
      } else {
        context.go(RouteNames.sales);
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
      title: 'Yeh bikri delete karein?',
      message: 'Yeh entry delete ho jayegi.',
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
      ref.invalidate(saleListProvider);
      if (mounted) context.go(RouteNames.sales);
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
    final cashCustomerAsync = ref.watch(cashCustomerPartyIdProvider);
    _cashCustomerPartyId = cashCustomerAsync.valueOrNull;

    if (widget.isEdit && widget.saleId != null) {
      final saleAsync = ref.watch(saleDetailProvider(widget.saleId!));
      return saleAsync.when(
        loading: () => const Scaffold(body: AppLoadingView()),
        error: (error, _) => Scaffold(
          body: AppErrorView(
            title: 'Bikri load nahi ho payi',
            message: UserErrorMessages.from(error),
            actionEnglish: 'Back', actionHindi: 'Wapas',
            onAction: () => context.pop(),
          ),
        ),
        data: (entry) {
          if (entry == null) {
            return Scaffold(
              body: AppErrorView(
                title: 'Bikri nahi mili',
                message: 'Yeh entry ab available nahi hai.',
                actionEnglish: 'Back', actionHindi: 'Wapas',
                onAction: () => context.pop(),
              ),
            );
          }
          if (!cashCustomerAsync.hasValue) {
            return const Scaffold(body: AppLoadingView());
          }
          if (!_editHydrated) {
            _applyEntry(entry, cashCustomerAsync.value);
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
        english: widget.isEdit ? 'Edit Sale' : 'Sale',
        hindi: widget.isEdit ? 'Bikri Badlo' : 'Bikri Likho',
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
                helper: 'Khali chhodein to cash bikri',
                allowClear: true,
              ),
              if (_selectedParty == null)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'Cash Bikri',
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
                      emptyText: 'Add item to sale',
                      emptyHindi: 'Maal jodein',
                      trailingIcon: Icons.add_circle_outline_rounded,
                    ),
                    if (_lines.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      ..._lines.asMap().entries.map((entry) {
                        return _SaleLineCard(
                          line: entry.value,
                          onChanged: () => setState(() {}),
                          onRemove: () {
                            setState(() {
                              _lines.removeAt(entry.key);
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

class _SaleLineCard extends StatefulWidget {
  const _SaleLineCard({
    required this.line,
    required this.onChanged,
    required this.onRemove,
  });

  final DraftSaleLine line;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  @override
  State<_SaleLineCard> createState() => _SaleLineCardState();
}

class _SaleLineCardState extends State<_SaleLineCard> {
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
