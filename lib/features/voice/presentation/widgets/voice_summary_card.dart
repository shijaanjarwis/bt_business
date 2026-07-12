import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_text_theme.dart';
import '../../../../core/theme/color_palette.dart';
import '../../domain/voice_draft.dart';
import '../../domain/voice_intent_type.dart';
import '../../engine/preview_generator.dart';

/// Read-only summary card shown before editing voice preview fields.
class VoiceSummaryCard extends StatelessWidget {
  const VoiceSummaryCard({
    super.key,
    required this.model,
    required this.needsReview,
  });

  final VoicePreviewModel model;
  final bool needsReview;

  @override
  Widget build(BuildContext context) {
    final text = context.appText;
    final draft = model.draft;
    final dateFormat = DateFormat('d MMM');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorPalette.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: needsReview ? ColorPalette.warningBorder : ColorPalette.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  draft.intent.hindiLabel,
                  style: text.primaryBold.copyWith(fontSize: 18),
                ),
              ),
              if (needsReview)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: ColorPalette.warningSurface,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Check karein',
                    style: text.helper.copyWith(color: ColorPalette.warningText),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (model.showParty && draft.partyName != null)
            _SummaryLine(label: 'Party', value: draft.partyName!),
          if (model.showItem && draft.itemName != null) ...[
            _SummaryLine(label: 'Maal', value: draft.itemName!),
            if (draft.quantity != null)
              _SummaryLine(
                label: 'Qty',
                value: '${_formatNum(draft.quantity)} ${draft.unit ?? ''}'.trim(),
              ),
            if (draft.rate != null)
              _SummaryLine(label: 'Rate', value: '₹${_formatNum(draft.rate)}'),
          ],
          if (model.showAmountOnly && (draft.amount ?? 0) > 0)
            _SummaryLine(label: 'Rupaye', value: '₹${_formatNum(draft.amount)}'),
          if (draft.intent == VoiceIntentType.expense && draft.expenseName != null)
            _SummaryLine(label: 'Kharch', value: draft.expenseName!),
          if (model.lineTotal > 0)
            _SummaryLine(label: 'Amount', value: '₹${_formatNum(model.lineTotal)}'),
          if (draft.paymentBreakdown.cash > 0)
            _SummaryLine(label: 'Cash', value: '₹${_formatNum(draft.paymentBreakdown.cash)}'),
          if (draft.paymentBreakdown.upi > 0)
            _SummaryLine(label: 'UPI', value: '₹${_formatNum(draft.paymentBreakdown.upi)}'),
          if (draft.paymentBreakdown.bank > 0)
            _SummaryLine(label: 'Bank', value: '₹${_formatNum(draft.paymentBreakdown.bank)}'),
          if (model.creditAmount > 0)
            _SummaryLine(label: 'Udhaar', value: '₹${_formatNum(model.creditAmount)}'),
          if (draft.reminderDate != null)
            _SummaryLine(
              label: 'Reminder',
              value: [
                dateFormat.format(draft.reminderDate!),
                if (draft.reminderTime != null) draft.reminderTime,
              ].join(' · '),
            ),
          if (draft.notes != null && draft.notes!.trim().isNotEmpty)
            _SummaryLine(label: 'Note', value: draft.notes!),
        ],
      ),
    );
  }

  static String _formatNum(double? value) {
    if (value == null) return '';
    if (value == value.roundToDouble()) return value.round().toString();
    return value.toStringAsFixed(2);
  }
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final text = context.appText;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(label, style: text.secondary.copyWith(fontSize: 14)),
          ),
          Expanded(
            child: Text(
              value,
              style: text.primaryBold.copyWith(fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }
}
