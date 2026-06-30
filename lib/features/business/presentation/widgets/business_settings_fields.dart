import 'package:flutter/material.dart';

import '../../../../core/theme/color_palette.dart';
import '../../domain/entities/currency.dart';
import '../../domain/entities/financial_year.dart';

/// Financial year start month selector.
class FinancialYearPicker extends StatelessWidget {
  const FinancialYearPicker({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int>(
      initialValue: value,
      decoration: InputDecoration(
        filled: true,
        fillColor: ColorPalette.cardSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
        ),
      ),
      items: FinancialYear.startMonths
          .map(
            (month) => DropdownMenuItem(
              value: month,
              child: Text(FinancialYear.labelForStartMonth(month)),
            ),
          )
          .toList(),
      onChanged: (month) {
        if (month != null) onChanged(month);
      },
    );
  }
}

/// Currency selector — extensible list, INR default in v1.
class CurrencyPicker extends StatelessWidget {
  const CurrencyPicker({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final BusinessCurrency value;
  final ValueChanged<BusinessCurrency> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<BusinessCurrency>(
      initialValue: value,
      decoration: InputDecoration(
        filled: true,
        fillColor: ColorPalette.cardSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
        ),
      ),
      items: BusinessCurrency.values
          .map(
            (currency) => DropdownMenuItem(
              value: currency,
              child: Text('${currency.symbol} ${currency.label} (${currency.code})'),
            ),
          )
          .toList(),
      onChanged: (currency) {
        if (currency != null) onChanged(currency);
      },
    );
  }
}
