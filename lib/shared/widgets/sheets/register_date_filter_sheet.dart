import 'package:flutter/material.dart';

import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/color_palette.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/register_date_period.dart';
import '../buttons/app_primary_button.dart';
import '../labels/bilingual_label.dart';

/// Professional date filter bottom sheet — Today, Week, Month, Custom range.
class RegisterDateFilterSheet {
  RegisterDateFilterSheet._();

  static Future<RegisterDateFilterResult?> show(
    BuildContext context, {
    required RegisterDatePeriod currentPeriod,
    required DateTime? customStart,
    required DateTime? customEnd,
  }) {
    return showModalBottomSheet<RegisterDateFilterResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: ColorPalette.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return _RegisterDateFilterSheetBody(
          initialPeriod: currentPeriod,
          initialStart: customStart ?? DateTime.now(),
          initialEnd: customEnd ?? DateTime.now(),
        );
      },
    );
  }
}

class RegisterDateFilterResult {
  const RegisterDateFilterResult({
    required this.period,
    this.customStart,
    this.customEnd,
    this.cleared = false,
  });

  final RegisterDatePeriod period;
  final DateTime? customStart;
  final DateTime? customEnd;
  final bool cleared;
}

class _RegisterDateFilterSheetBody extends StatefulWidget {
  const _RegisterDateFilterSheetBody({
    required this.initialPeriod,
    required this.initialStart,
    required this.initialEnd,
  });

  final RegisterDatePeriod initialPeriod;
  final DateTime initialStart;
  final DateTime initialEnd;

  @override
  State<_RegisterDateFilterSheetBody> createState() =>
      _RegisterDateFilterSheetBodyState();
}

class _RegisterDateFilterSheetBodyState extends State<_RegisterDateFilterSheetBody> {
  late RegisterDatePeriod _period;
  late DateTime _start;
  late DateTime _end;

  @override
  void initState() {
    super.initState();
    _period = widget.initialPeriod;
    _start = widget.initialStart;
    _end = widget.initialEnd;
  }

  Future<void> _pickStart() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _start,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _start = picked;
        _period = RegisterDatePeriod.custom;
      });
    }
  }

  Future<void> _pickEnd() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _end,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _end = picked;
        _period = RegisterDatePeriod.custom;
      });
    }
  }

  void _selectPreset(RegisterDatePeriod period) {
    setState(() => _period = period);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, bottomInset + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: ColorPalette.border,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const BilingualLabel(
            english: 'Date Filter',
            hindi: 'Tareekh Chunein',
            compact: true,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _PresetTile(
                english: 'Today',
                hindi: 'Aaj',
                selected: _period == RegisterDatePeriod.today,
                onTap: () => _selectPreset(RegisterDatePeriod.today),
              ),
              _PresetTile(
                english: 'Yesterday',
                hindi: 'Kal',
                selected: _period == RegisterDatePeriod.yesterday,
                onTap: () => _selectPreset(RegisterDatePeriod.yesterday),
              ),
              _PresetTile(
                english: 'This Week',
                hindi: 'Is Hafte',
                selected: _period == RegisterDatePeriod.thisWeek,
                onTap: () => _selectPreset(RegisterDatePeriod.thisWeek),
              ),
              _PresetTile(
                english: 'This Month',
                hindi: 'Is Mahine',
                selected: _period == RegisterDatePeriod.thisMonth,
                onTap: () => _selectPreset(RegisterDatePeriod.thisMonth),
              ),
              _PresetTile(
                english: 'Custom Date',
                hindi: 'Apni Tareekh',
                selected: _period == RegisterDatePeriod.custom,
                onTap: () => _selectPreset(RegisterDatePeriod.custom),
              ),
            ],
          ),
          if (_period == RegisterDatePeriod.custom) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _DatePickTile(
                    english: 'From',
                    hindi: 'Se',
                    date: _start,
                    onTap: _pickStart,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _DatePickTile(
                    english: 'To',
                    hindi: 'Tak',
                    date: _end,
                    onTap: _pickEnd,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 20),
          AppPrimaryButton(
            english: 'Apply',
            hindi: 'Lagu Karein',
            onPressed: () {
              Navigator.pop(
                context,
                RegisterDateFilterResult(
                  period: _period,
                  customStart: _period == RegisterDatePeriod.custom ? _start : null,
                  customEnd: _period == RegisterDatePeriod.custom ? _end : null,
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: AppSecondaryButton(
                  english: 'Cancel',
                  hindi: 'Cancel',
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AppSecondaryButton(
                  english: 'Clear',
                  hindi: 'Saaf Karein',
                  onPressed: () {
                    Navigator.pop(
                      context,
                      const RegisterDateFilterResult(
                        period: RegisterDatePeriod.today,
                        cleared: true,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PresetTile extends StatelessWidget {
  const _PresetTile({
    required this.english,
    required this.hindi,
    required this.selected,
    required this.onTap,
  });

  final String english;
  final String hindi;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? ColorPalette.purple.withValues(alpha: 0.12)
          : ColorPalette.background,
      borderRadius: BorderRadius.circular(AppDimensions.chipRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.chipRadius),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimensions.chipRadius),
            border: Border.all(
              color: selected ? ColorPalette.purple : ColorPalette.border,
            ),
          ),
          child: BilingualLabel(
            english: english,
            hindi: hindi,
            compact: true,
          ),
        ),
      ),
    );
  }
}

class _DatePickTile extends StatelessWidget {
  const _DatePickTile({
    required this.english,
    required this.hindi,
    required this.date,
    required this.onTap,
  });

  final String english;
  final String hindi;
  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ColorPalette.background,
      borderRadius: BorderRadius.circular(AppDimensions.chipRadius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BilingualLabel(english: english, hindi: hindi, compact: true),
              const SizedBox(height: 6),
              Text(
                DateFormatter.shortDate(date),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: ColorPalette.labelPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
