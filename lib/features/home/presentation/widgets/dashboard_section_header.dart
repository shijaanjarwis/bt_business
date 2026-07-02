import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../shared/widgets/labels/bilingual_label.dart';

/// Section divider label for grouped dashboard cards.
class DashboardSectionHeader extends StatelessWidget {
  const DashboardSectionHeader({
    super.key,
    required this.english,
    required this.hindi,
  });

  final String english;
  final String hindi;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm, top: AppSpacing.xs),
      child: BilingualLabel(
        english: english,
        hindi: hindi,
        compact: true,
      ),
    );
  }
}
