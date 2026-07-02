import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../reports/data/datasources/transaction_history_local_datasource.dart';
import '../../../../shared/widgets/labels/bilingual_label.dart';
import '../utils/dashboard_activity_navigation.dart';

/// Last five register entries with tap-to-open.
class DashboardRecentActivitySection extends StatelessWidget {
  const DashboardRecentActivitySection({
    super.key,
    required this.entries,
  });

  final List<TransactionHistoryEntry> entries;

  static final _timeFormat = DateFormat('h:mm a');

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const BilingualLabel(
          english: 'Recent Activity',
          hindi: 'Abhi Ka Kaam',
          compact: true,
        ),
        const SizedBox(height: AppSpacing.md),
        if (entries.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: ColorPalette.cardSurface,
              borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
              border: Border.all(color: ColorPalette.border),
            ),
            child: const BilingualLabel(
              english: 'No entries yet',
              hindi: 'Pehli sale likho',
              compact: true,
            ),
          )
        else
          ...entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Material(
                color: ColorPalette.cardSurface,
                borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => DashboardActivityNavigation.open(context, entry),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.md,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: ColorPalette.border),
                      borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.partyName?.trim().isNotEmpty == true
                                    ? entry.partyName!
                                    : 'Cash / Kharch',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: ColorPalette.labelPrimary,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                entry.label,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: ColorPalette.labelSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              CurrencyFormatter.format(entry.amount),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: ColorPalette.labelPrimary,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              _timeFormat.format(entry.createdAt),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: ColorPalette.labelSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
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
