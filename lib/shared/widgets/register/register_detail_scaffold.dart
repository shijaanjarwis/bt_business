import 'package:flutter/material.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/color_palette.dart';
import '../../../core/utils/currency_formatter.dart';
import '../labels/bilingual_label.dart';
import '../scaffold/app_register_app_bar.dart';

/// Read-only detail row — English label, value, optional Hindi subtitle.
class RegisterDetailRow extends StatelessWidget {
  const RegisterDetailRow({
    super.key,
    required this.english,
    required this.hindi,
    required this.value,
    this.valueColor,
  });

  final String english;
  final String hindi;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: BilingualLabel(
              english: english,
              hindi: hindi,
              compact: true,
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: valueColor ?? ColorPalette.labelPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shared read-only register detail layout.
class RegisterDetailScaffold extends StatelessWidget {
  const RegisterDetailScaffold({
    super.key,
    required this.englishTitle,
    required this.hindiTitle,
    required this.children,
    this.onEdit,
  });

  final String englishTitle;
  final String hindiTitle;
  final List<Widget> children;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorPalette.background,
      appBar: AppRegisterAppBar(
        english: englishTitle,
        hindi: hindiTitle,
        actions: [
          if (onEdit != null)
            IconButton(
              tooltip: 'Edit',
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined, color: ColorPalette.iconPrimary),
            ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ColorPalette.cardSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: ColorPalette.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Line item block for sale/purchase detail pages.
class RegisterLineItemTile extends StatelessWidget {
  const RegisterLineItemTile({
    super.key,
    required this.itemName,
    required this.qty,
    required this.rate,
    required this.amount,
  });

  final String itemName;
  final double qty;
  final double rate;
  final double amount;

  @override
  Widget build(BuildContext context) {
    final qtyLabel = qty == qty.roundToDouble()
        ? qty.round().toString()
        : qty.toStringAsFixed(2);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            itemName,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: ColorPalette.labelPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$qtyLabel × ${CurrencyFormatter.format(rate)}',
            style: const TextStyle(
              fontSize: 13,
              color: ColorPalette.labelSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              CurrencyFormatter.format(amount),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: ColorPalette.purple,
              ),
            ),
          ),
          const Divider(height: 20),
        ],
      ),
    );
  }
}
