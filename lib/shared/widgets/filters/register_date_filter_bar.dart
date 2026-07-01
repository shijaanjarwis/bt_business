import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/color_palette.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/register_date_period.dart';

typedef RegisterDateFilterChanged = void Function(RegisterDatePeriod period);

/// Today · This Week · This Month · More — shared register date chips.
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

  Future<void> _openMoreSheet(BuildContext context) async {
    var start = customStart ?? DateTime.now();
    var end = customEnd ?? DateTime.now();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.viewPaddingOf(context).bottom + 20,
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              Future<void> pickStart() async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: start,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  setModalState(() => start = picked);
                }
              }

              Future<void> pickEnd() async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: end,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  setModalState(() => end = picked);
                }
              }

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Date Range',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1C1C1E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Tareekh chunein',
                    style: TextStyle(fontSize: 13, color: Color(0xFF48484A)),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _DatePickTile(
                          label: 'Se',
                          date: start,
                          onTap: pickStart,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _DatePickTile(
                          label: 'Tak',
                          date: end,
                          onTap: pickEnd,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () {
                      onPeriodChanged(RegisterDatePeriod.custom);
                      onCustomRangeChanged(start, end);
                      Navigator.pop(context);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: ColorPalette.purple,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Apply'),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final value in [
            RegisterDatePeriod.today,
            RegisterDatePeriod.thisWeek,
            RegisterDatePeriod.thisMonth,
          ])
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(value.hindiLabel),
                selected: period == value,
                onSelected: (_) => onPeriodChanged(value),
                selectedColor: ColorPalette.purple.withValues(alpha: 0.15),
                checkmarkColor: ColorPalette.purple,
              ),
            ),
          FilterChip(
            label: const Text('Aur…'),
            selected: period == RegisterDatePeriod.custom,
            onSelected: (_) => _openMoreSheet(context),
            selectedColor: ColorPalette.purple.withValues(alpha: 0.15),
            checkmarkColor: ColorPalette.purple,
          ),
        ],
      ),
    );
  }
}

class _DatePickTile extends StatelessWidget {
  const _DatePickTile({
    required this.label,
    required this.date,
    required this.onTap,
  });

  final String label;
  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF48484A))),
              const SizedBox(height: 4),
              Text(
                DateFormatter.shortDate(date),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
