import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/accounting/payment_breakdown.dart';
import '../../../../core/theme/app_text_theme.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../shared/widgets/branding/developer_footer.dart';
import '../../../../shared/widgets/buttons/app_primary_button.dart';
import '../../../../shared/widgets/feedback/app_loading_view.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';
import '../../../../shared/widgets/layout/app_form_section.dart';
import '../../../../shared/widgets/scaffold/app_register_app_bar.dart';
import '../../domain/voice_draft.dart';
import '../../domain/voice_intent_type.dart';
import '../../domain/voice_memory.dart';
import '../../engine/preview_generator.dart';
import '../widgets/voice_summary_card.dart';
import '../widgets/voice_suggestions_strip.dart';
import '../services/voice_save_executor.dart';

/// Mandatory preview — user must review and edit before save.
class VoicePreviewPage extends ConsumerStatefulWidget {
  const VoicePreviewPage({
    super.key,
    required this.resolved,
  });

  final VoiceResolvedDraft resolved;

  @override
  ConsumerState<VoicePreviewPage> createState() => _VoicePreviewPageState();
}

class _VoicePreviewPageState extends ConsumerState<VoicePreviewPage> {
  late VoiceDraft _draft;
  late String? _partyId;
  late String? _itemId;
  late bool _createParty;
  late bool _createItem;
  late Map<VoiceConfidenceField, VoiceConfidenceLevel> _confidence;
  late bool _memoryUsed;
  late double _overallConfidence;
  late final ScrollController _scrollController;

  late final TextEditingController _partyController;
  late final TextEditingController _itemController;
  late final TextEditingController _qtyController;
  late final TextEditingController _unitController;
  late final TextEditingController _rateController;
  late final TextEditingController _cashController;
  late final TextEditingController _upiController;
  late final TextEditingController _bankController;
  late final TextEditingController _amountController;
  late final TextEditingController _expenseController;
  late final TextEditingController _notesController;

  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _draft = widget.resolved.draft;
    _partyId = widget.resolved.partyId;
    _itemId = widget.resolved.itemId;
    _createParty = widget.resolved.createParty;
    _createItem = widget.resolved.createItem;
    _confidence = widget.resolved.confidence;
    _memoryUsed = widget.resolved.memoryUsed;
    _overallConfidence = widget.resolved.overallConfidence;
    _scrollController = ScrollController();

    _partyController = TextEditingController(text: _draft.partyName ?? '');
    _itemController = TextEditingController(text: _draft.itemName ?? '');
    _qtyController = TextEditingController(text: _format(_draft.quantity));
    _unitController = TextEditingController(text: _draft.unit ?? '');
    _rateController = TextEditingController(text: _format(_draft.rate));
    _cashController = TextEditingController(text: _format(_draft.paymentBreakdown.cash));
    _upiController = TextEditingController(text: _format(_draft.paymentBreakdown.upi));
    _bankController = TextEditingController(text: _format(_draft.paymentBreakdown.bank));
    _amountController = TextEditingController(text: _format(_draft.amount));
    _expenseController = TextEditingController(text: _draft.expenseName ?? '');
    _notesController = TextEditingController(text: _draft.notes ?? '');
  }

  @override
  void dispose() {
    _partyController.dispose();
    _itemController.dispose();
    _qtyController.dispose();
    _unitController.dispose();
    _rateController.dispose();
    _cashController.dispose();
    _upiController.dispose();
    _bankController.dispose();
    _amountController.dispose();
    _expenseController.dispose();
    _notesController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _format(double? value) {
    if (value == null || value <= 0) return '';
    if (value == value.roundToDouble()) return value.round().toString();
    return value.toStringAsFixed(2);
  }

  double _parse(TextEditingController controller) =>
      double.tryParse(controller.text.trim()) ?? 0;

  VoiceDraft _buildDraftFromFields() {
    final breakdown = PaymentBreakdown(
      cash: _parse(_cashController),
      upi: _parse(_upiController),
      bank: _parse(_bankController),
    );

    return _draft.copyWith(
      partyName: _partyController.text.trim().isEmpty ? null : _partyController.text.trim(),
      itemName: _itemController.text.trim().isEmpty ? null : _itemController.text.trim(),
      unit: _unitController.text.trim().isEmpty ? null : _unitController.text.trim(),
      quantity: _parse(_qtyController) > 0 ? _parse(_qtyController) : null,
      rate: _parse(_rateController) > 0 ? _parse(_rateController) : null,
      amount: _parse(_amountController) > 0 ? _parse(_amountController) : null,
      expenseName:
          _expenseController.text.trim().isEmpty ? null : _expenseController.text.trim(),
      paymentBreakdown: breakdown,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );
  }

  Future<void> _save() async {
    setState(() {
      _isSaving = true;
      _error = null;
    });

    final draft = _buildDraftFromFields();
    final result = await VoiceSaveExecutor(ref: ref).save(
      draft: draft,
      partyId: _partyId,
      itemId: _itemId,
      createParty: _createParty,
      createItem: _createItem,
    );

    if (!mounted) return;

    if (result.isFailure) {
      setState(() {
        _error = result.failureOrNull!.message;
        _isSaving = false;
      });
      return;
    }

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Entry save ho gayi')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final draft = _draft;
    final built = _buildDraftFromFields();
    final previewModel = PreviewGenerator.fromResolved(
      widget.resolved.copyWith(draft: built, confidence: _confidence),
    );
    final total = built.lineTotal;
    final credit = built.creditAmount;
    final dateFormat = DateFormat('d MMM');
    final needsReview = _overallConfidence < 0.90 || _memoryUsed;
    final text = context.appText;

    return Scaffold(
      backgroundColor: ColorPalette.background,
      appBar: const AppRegisterAppBar(
        english: 'Voice Preview',
        hindi: 'Awaz Se Entry',
      ),
      body: _isSaving
          ? const AppLoadingView()
          : ListView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              children: [
                VoiceSummaryCard(model: previewModel, needsReview: needsReview),
                const SizedBox(height: 16),
                VoiceSuggestionsStrip(
                  onPartyTap: (name) => setState(() => _partyController.text = name),
                  onItemTap: (name) => setState(() => _itemController.text = name),
                ),
                const SizedBox(height: 16),
                if (needsReview)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: ColorPalette.warningSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: ColorPalette.warningBorder),
                    ),
                    child: Text(
                      'Kuch fields kam pakke hain — neeche check karke save karein.',
                      style: text.helper.copyWith(
                        fontSize: 14,
                        color: ColorPalette.warningText,
                      ),
                    ),
                  ),
                if (_memoryUsed)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: ColorPalette.purple.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.psychology_outlined, color: ColorPalette.purple, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Yaad se bhara — please check karein, phir save karein',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                AppFormSection(
                  english: 'Edit',
                  hindi: 'Theek Karein',
                  child: Column(
                    children: [
                      _PreviewRow(
                        label: 'Type',
                        value: draft.intent.hindiLabel,
                      ),
                      if (_showParty(draft.intent))
                        _ConfidenceField(
                          field: VoiceConfidenceField.party,
                          confidence: _confidence,
                          child: AppTextField(
                            english: 'Party',
                            hindi: 'Party',
                            controller: _partyController,
                          ),
                        ),
                      if (_showItem(draft.intent) || draft.intent == VoiceIntentType.createItem) ...[
                        const SizedBox(height: 12),
                        _ConfidenceField(
                          field: VoiceConfidenceField.item,
                          confidence: _confidence,
                          child: AppTextField(
                            english: 'Item',
                            hindi: 'Maal',
                            controller: _itemController,
                          ),
                        ),
                        if (draft.intent == VoiceIntentType.createItem ||
                            _showItem(draft.intent)) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              if (draft.intent != VoiceIntentType.createItem)
                                Expanded(
                                  child: _ConfidenceField(
                                    field: VoiceConfidenceField.quantity,
                                    confidence: _confidence,
                                    child: AppTextField(
                                      english: 'Qty',
                                      hindi: 'Matra',
                                      controller: _qtyController,
                                      keyboardType: TextInputType.number,
                                    ),
                                  ),
                                ),
                              if (draft.intent != VoiceIntentType.createItem)
                                const SizedBox(width: 10),
                              Expanded(
                                child: _ConfidenceField(
                                  field: VoiceConfidenceField.unit,
                                  confidence: _confidence,
                                  child: AppTextField(
                                    english: 'Unit',
                                    hindi: 'Unit',
                                    controller: _unitController,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (_showItem(draft.intent)) ...[
                          const SizedBox(height: 12),
                          _ConfidenceField(
                            field: VoiceConfidenceField.rate,
                            confidence: _confidence,
                            child: AppTextField(
                              english: 'Rate',
                              hindi: 'Rate',
                              controller: _rateController,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ],
                      if (_showAmountOnly(draft.intent)) ...[
                        const SizedBox(height: 12),
                        AppTextField(
                          english: 'Amount',
                          hindi: 'Rupaye',
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                        ),
                      ],
                      if (draft.intent == VoiceIntentType.expense) ...[
                        const SizedBox(height: 12),
                        AppTextField(
                          english: 'Expense',
                          hindi: 'Kharch',
                          controller: _expenseController,
                        ),
                      ],
                      if (_showPaymentSplit(draft.intent)) ...[
                        const SizedBox(height: 16),
                        AppTextField(
                          english: 'Cash',
                          hindi: 'Cash',
                          controller: _cashController,
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 12),
                        AppTextField(
                          english: 'UPI',
                          hindi: 'UPI',
                          controller: _upiController,
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 12),
                        AppTextField(
                          english: 'Bank',
                          hindi: 'Bank',
                          controller: _bankController,
                          keyboardType: TextInputType.number,
                        ),
                      ],
                      if (_showItem(draft.intent) && total > 0) ...[
                        const SizedBox(height: 12),
                        _PreviewRow(label: 'Total', value: '₹${total.toStringAsFixed(0)}'),
                        _PreviewRow(
                          label: 'Udhaar',
                          value: credit > 0 ? '₹${credit.toStringAsFixed(0)}' : '₹0',
                        ),
                      ],
                      if (draft.reminderDate != null) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _PreviewRow(
                                label: 'Reminder',
                                value: [
                                  dateFormat.format(draft.reminderDate!),
                                  if (draft.reminderTime != null) draft.reminderTime,
                                ].join(' · '),
                              ),
                            ),
                            _ConfidenceChip(level: _confidence[VoiceConfidenceField.reminder]),
                          ],
                        ),
                      ],
                      const SizedBox(height: 12),
                      AppTextField(
                        english: 'Note',
                        hindi: 'Note',
                        controller: _notesController,
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: const TextStyle(color: ColorPalette.destructive),
                  ),
                ],
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSaving
                            ? null
                            : () => _scrollController.animateTo(
                                  280,
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeOut,
                                ),
                        child: const Text('Edit'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSaving ? null : () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                AppPrimaryButton(
                  english: 'Save',
                  hindi: 'Save Karein',
                  isLoading: _isSaving,
                  onPressed: _save,
                ),
                const DeveloperFooter(),
              ],
            ),
    );
  }

  bool _showParty(VoiceIntentType intent) {
    return switch (intent) {
      VoiceIntentType.sale ||
      VoiceIntentType.purchase ||
      VoiceIntentType.paymentReceived ||
      VoiceIntentType.paymentPaid ||
      VoiceIntentType.createParty ||
      VoiceIntentType.reminder =>
        true,
      _ => false,
    };
  }

  bool _showItem(VoiceIntentType intent) {
    return intent == VoiceIntentType.sale || intent == VoiceIntentType.purchase;
  }

  bool _showAmountOnly(VoiceIntentType intent) {
    return intent == VoiceIntentType.paymentReceived ||
        intent == VoiceIntentType.paymentPaid ||
        intent == VoiceIntentType.expense ||
        intent == VoiceIntentType.reminder;
  }

  bool _showPaymentSplit(VoiceIntentType intent) {
    return intent == VoiceIntentType.sale ||
        intent == VoiceIntentType.purchase ||
        intent == VoiceIntentType.paymentReceived ||
        intent == VoiceIntentType.paymentPaid;
  }
}

class _ConfidenceField extends StatelessWidget {
  const _ConfidenceField({
    required this.field,
    required this.confidence,
    required this.child,
  });

  final VoiceConfidenceField field;
  final Map<VoiceConfidenceField, VoiceConfidenceLevel> confidence;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final level = confidence[field];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (level != null) ...[
          Align(
            alignment: Alignment.centerRight,
            child: _ConfidenceChip(level: level),
          ),
          const SizedBox(height: 4),
        ],
        DecoratedBox(
          decoration: level == VoiceConfidenceLevel.low
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: ColorPalette.warningText.withValues(alpha: 0.7)),
                )
              : const BoxDecoration(),
          child: Padding(
            padding: level == VoiceConfidenceLevel.low
                ? const EdgeInsets.all(4)
                : EdgeInsets.zero,
            child: child,
          ),
        ),
      ],
    );
  }
}

class _ConfidenceChip extends StatelessWidget {
  const _ConfidenceChip({required this.level});

  final VoiceConfidenceLevel? level;

  @override
  Widget build(BuildContext context) {
    if (level == null) return const SizedBox.shrink();

    final color = switch (level!) {
      VoiceConfidenceLevel.high => ColorPalette.accentGreen,
      VoiceConfidenceLevel.medium => ColorPalette.purple,
      VoiceConfidenceLevel.low => ColorPalette.warningText,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'Yaad · ${level!.hindiLabel}',
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  const _PreviewRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: context.appText.secondary.copyWith(fontSize: 14),
            ),
          ),
          Text(
            value,
            style: context.appText.primaryBold.copyWith(fontSize: 15),
          ),
        ],
      ),
    );
  }
}
