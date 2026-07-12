import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/accounting/payment_breakdown.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/color_palette.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/accounting/payment_method_channel.dart';
import '../labels/bilingual_label.dart';
import 'payment_method_selector.dart';

typedef PaymentBreakdownChanged = void Function({
  required double cash,
  required double upi,
  required double bank,
});

/// Register-style split payment inputs with auto remaining credit.
class PaymentBreakdownFields extends StatelessWidget {
  const PaymentBreakdownFields({
    super.key,
    required this.grandTotal,
    required this.cashController,
    required this.upiController,
    required this.bankController,
    required this.onChanged,
    this.totalLabel = 'Total Amount',
    this.creditLabel = 'Credit (Remaining)',
    this.selectedMethod = PaymentMethodChannel.cash,
    this.onMethodSelected,
  });

  final double grandTotal;
  final TextEditingController cashController;
  final TextEditingController upiController;
  final TextEditingController bankController;
  final PaymentBreakdownChanged onChanged;
  final String totalLabel;
  final String creditLabel;
  final PaymentMethodChannel selectedMethod;
  final ValueChanged<PaymentMethodChannel>? onMethodSelected;

  double _parse(TextEditingController controller) =>
      double.tryParse(controller.text.trim()) ?? 0;

  double get _paidTotal =>
      _parse(cashController) + _parse(upiController) + _parse(bankController);

  double get _remainingCredit => grandTotal - _paidTotal;

  bool get _isOverpaid => _paidTotal > grandTotal && grandTotal > 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SummaryRow(
          label: totalLabel,
          value: CurrencyFormatter.format(grandTotal),
          emphasized: true,
        ),
        const Divider(height: 20),
        if (onMethodSelected != null) ...[
          const Text(
            'Payment Method',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: ColorPalette.labelPrimary,
            ),
          ),
          const SizedBox(height: 8),
          PaymentMethodSelector(
            selected: selectedMethod,
            onChanged: onMethodSelected!,
          ),
          const SizedBox(height: 12),
        ],
        _AmountField(
          label: 'Cash',
          controller: cashController,
          onChanged: () => onChanged(
            cash: _parse(cashController),
            upi: _parse(upiController),
            bank: _parse(bankController),
          ),
        ),
        _AmountField(
          label: 'UPI',
          controller: upiController,
          onChanged: () => onChanged(
            cash: _parse(cashController),
            upi: _parse(upiController),
            bank: _parse(bankController),
          ),
        ),
        _AmountField(
          label: 'Bank',
          controller: bankController,
          onChanged: () => onChanged(
            cash: _parse(cashController),
            upi: _parse(upiController),
            bank: _parse(bankController),
          ),
        ),
        const SizedBox(height: 8),
        _SummaryRow(
          label: creditLabel,
          value: CurrencyFormatter.format(
            _isOverpaid ? 0 : _remainingCredit.clamp(0, double.infinity),
          ),
          valueColor: _isOverpaid
              ? ColorPalette.destructive
              : (_remainingCredit > 0
                  ? ColorPalette.accentOrange
                  : ColorPalette.labelSecondary),
        ),
        if (_isOverpaid) ...[
          const SizedBox(height: 6),
          const Text(
            'Zyada rashi — total se kam likhein',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: ColorPalette.destructive,
            ),
          ),
        ],
      ],
    );
  }
}

/// Read-only payment breakdown for sale/purchase detail screens.
class PaymentBreakdownDisplay extends StatelessWidget {
  const PaymentBreakdownDisplay({
    super.key,
    required this.breakdown,
    required this.grandTotal,
    this.creditEnglish = 'Credit',
    this.creditHindi = 'Udhaar',
  });

  final PaymentBreakdown breakdown;
  final double grandTotal;
  final String creditEnglish;
  final String creditHindi;

  @override
  Widget build(BuildContext context) {
    final credit = breakdown.remainingCredit(grandTotal);
    final rows = <({String english, String hindi, double amount})>[
      if (breakdown.cash > 0)
        (english: 'Cash', hindi: 'Cash', amount: breakdown.cash),
      if (breakdown.upi > 0)
        (english: 'UPI', hindi: 'UPI', amount: breakdown.upi),
      if (breakdown.bank > 0)
        (english: 'Bank', hindi: 'Bank', amount: breakdown.bank),
      if (credit > 0)
        (english: creditEnglish, hindi: creditHindi, amount: credit),
    ];

    if (rows.isEmpty && grandTotal > 0) {
      rows.add((
        english: creditEnglish,
        hindi: creditHindi,
        amount: grandTotal,
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.xs),
          _BreakdownLine(
            english: rows[i].english,
            hindi: rows[i].hindi,
            amount: rows[i].amount,
            emphasized: rows[i].english == creditEnglish,
          ),
        ],
      ],
    );
  }
}

class _BreakdownLine extends StatelessWidget {
  const _BreakdownLine({
    required this.english,
    required this.hindi,
    required this.amount,
    this.emphasized = false,
  });

  final String english;
  final String hindi;
  final double amount;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: BilingualLabel(
            english: english,
            hindi: hindi,
            compact: true,
          ),
        ),
        Text(
          CurrencyFormatter.format(amount),
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: emphasized
                ? ColorPalette.accentOrange
                : ColorPalette.labelPrimary,
          ),
        ),
      ],
    );
  }
}

class _AmountField extends StatelessWidget {
  const _AmountField({
    required this.label,
    required this.controller,
    required this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          SizedBox(
            width: 120,
            child: TextFormField(
              controller: controller,
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
              onChanged: (_) => onChanged(),
            ),
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
