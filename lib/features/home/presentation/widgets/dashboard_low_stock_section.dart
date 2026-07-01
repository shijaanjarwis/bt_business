import 'package:flutter/material.dart';

import '../../../../core/theme/color_palette.dart';
import '../../../items/domain/entities/item.dart';

/// Low-stock warning — hidden when the list is empty.
class DashboardLowStockSection extends StatelessWidget {
  const DashboardLowStockSection({
    super.key,
    required this.items,
  });

  final List<Item> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Kam Stock',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1C1C1E),
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Ye maal jaldi khatam ho sakta hai',
          style: TextStyle(
            fontSize: 13,
            color: ColorPalette.labelSecondary,
          ),
        ),
        const SizedBox(height: 12),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF4E5),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFFD9A0)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.inventory_2_outlined,
                    color: Color(0xFFFF9500),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1C1C1E),
                      ),
                    ),
                  ),
                  Text(
                    '${item.openingStock.toStringAsFixed(item.openingStock % 1 == 0 ? 0 : 1)} ${item.unit}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFBF5F00),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
