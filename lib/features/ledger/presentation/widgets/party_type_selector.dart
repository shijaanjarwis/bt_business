import 'package:flutter/material.dart';

import '../../../../core/theme/color_palette.dart';
import '../../../../shared/widgets/labels/bilingual_label.dart';
import '../../domain/entities/party_type.dart';

class PartyTypeSelector extends StatelessWidget {
  const PartyTypeSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final PartyType value;
  final ValueChanged<PartyType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const BilingualLabel(
          english: 'Party Type',
          hindi: 'Customer ya Supplier chuniye',
          compact: true,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: PartyType.values.map((type) {
            final selected = value == type;
            return ChoiceChip(
              label: Text('${type.englishLabel} · ${type.hindiLabel}'),
              selected: selected,
              onSelected: (_) => onChanged(type),
              selectedColor: ColorPalette.purple.withValues(alpha: 0.15),
              labelStyle: TextStyle(
                color: selected ? ColorPalette.purple : const Color(0xFF636366),
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
              side: BorderSide(
                color: selected ? ColorPalette.purple : const Color(0xFFE5E5EA),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
