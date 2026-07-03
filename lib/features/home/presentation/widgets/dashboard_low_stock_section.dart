import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../shared/widgets/labels/bilingual_label.dart';
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
        const BilingualLabel(
          english: 'Low Stock',
          hindi: 'Kam Stock',
          compact: true,
        ),
        const SizedBox(height: AppSpacing.xs),
        const Text(
          'Ye maal jaldi khatam ho sakta hai',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: ColorPalette.labelSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Material(
              color: ColorPalette.warningSurface,
              borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => context.push(RouteNames.stockEditPath(item.id)),
                child: Ink(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: ColorPalette.warningBorder),
                    borderRadius:
                        BorderRadius.circular(AppDimensions.cardRadius),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.md,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          color: ColorPalette.accentOrange,
                          size: AppDimensions.iconSizeSm,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            item.name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: ColorPalette.labelPrimary,
                            ),
                          ),
                        ),
                        Text(
                          '${item.openingStock.toStringAsFixed(item.openingStock % 1 == 0 ? 0 : 1)} ${item.unit}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: ColorPalette.warningText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
