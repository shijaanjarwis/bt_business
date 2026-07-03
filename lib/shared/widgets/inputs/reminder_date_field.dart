import 'package:flutter/material.dart';

import '../../../core/theme/color_palette.dart';
import '../../../core/utils/date_formatter.dart';
import '../labels/bilingual_label.dart';

/// Optional next reminder date — used on sale, purchase, and payment forms.
class ReminderDateField extends StatelessWidget {
  const ReminderDateField({
    super.key,
    required this.reminderDate,
    required this.onChanged,
    this.enabled = true,
  });

  final DateTime? reminderDate;
  final ValueChanged<DateTime?> onChanged;
  final bool enabled;

  Future<void> _pickDate(BuildContext context) async {
    if (!enabled) return;

    final picked = await showDatePicker(
      context: context,
      initialDate: reminderDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );
    if (picked != null) {
      onChanged(
        DateTime(picked.year, picked.month, picked.day),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasDate = reminderDate != null;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      enabled: enabled,
      title: const BilingualLabel(
        english: 'Next Reminder Date',
        hindi: 'Agla Reminder',
        compact: true,
      ),
      subtitle: Text(
        hasDate
            ? DateFormatter.shortDate(reminderDate!)
            : 'Optional — khali chhod sakte hain',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: hasDate
              ? ColorPalette.labelPrimary
              : ColorPalette.labelSecondary,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasDate && enabled)
            IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: 'Clear reminder',
              onPressed: () => onChanged(null),
              icon: const Icon(Icons.close_rounded, size: 18),
            ),
          Icon(
            Icons.notifications_outlined,
            size: 20,
            color: enabled ? ColorPalette.iconPrimary : ColorPalette.labelSecondary,
          ),
        ],
      ),
      onTap: enabled ? () => _pickDate(context) : null,
    );
  }
}
