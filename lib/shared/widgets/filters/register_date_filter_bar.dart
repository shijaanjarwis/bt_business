import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/color_palette.dart';
import '../../../core/utils/register_date_period.dart';
import '../chips/app_filter_chip.dart';
import '../sheets/register_date_filter_sheet.dart';

typedef RegisterDateFilterChanged = void Function(RegisterDatePeriod period);

/// Today · This Week · This Month · Custom — shared register date chips.
class RegisterDateFilterBar extends ConsumerWidget {
  const RegisterDateFilterBar({
    super.key,
    required this.period,
    required this.customStart,
    required this.customEnd,
    required this.onPeriodChanged,
    required this.onCustomRangeChanged,
  });

  final RegisterDatePeriod period;
  final DateTime? customStart;
  final DateTime? customEnd;
  final RegisterDateFilterChanged onPeriodChanged;
  final void Function(DateTime start, DateTime end) onCustomRangeChanged;

  Future<void> _openFilterSheet(BuildContext context) async {
    final result = await RegisterDateFilterSheet.show(
      context,
      currentPeriod: period,
      customStart: customStart,
      customEnd: customEnd,
    );
    if (result == null) return;

    if (result.cleared) {
      onPeriodChanged(RegisterDatePeriod.today);
      return;
    }

    onPeriodChanged(result.period);
    if (result.period == RegisterDatePeriod.custom &&
        result.customStart != null &&
        result.customEnd != null) {
      onCustomRangeChanged(result.customStart!, result.customEnd!);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final value in [
            RegisterDatePeriod.today,
            RegisterDatePeriod.yesterday,
            RegisterDatePeriod.thisWeek,
            RegisterDatePeriod.thisMonth,
          ])
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: AppFilterChip(
                label: value.englishLabel,
                selected: period == value,
                onSelected: () => onPeriodChanged(value),
              ),
            ),
          AppFilterChip(
            label: period == RegisterDatePeriod.custom
                ? 'Custom'
                : RegisterDatePeriod.custom.englishLabel,
            selected: period == RegisterDatePeriod.custom,
            onSelected: () => _openFilterSheet(context),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: IconButton(
              tooltip: 'Date filter',
              onPressed: () => _openFilterSheet(context),
              icon: const Icon(
                Icons.calendar_month_outlined,
                color: ColorPalette.iconPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
