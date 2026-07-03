import 'package:flutter/material.dart';

import '../../../core/localization/label_registry.dart';
import '../../../core/theme/app_text_theme.dart';

/// English heading with daily spoken Hindi subtitle — mandatory on every screen.
///
/// BT Business is not a translated app. Assistant language settings never
/// remove or replace these labels. Use [fromKey] for [LabelRegistry] labels.
class BilingualLabel extends StatelessWidget {
  const BilingualLabel({
    super.key,
    required this.english,
    required this.hindi,
    this.englishStyle,
    this.hindiStyle,
    this.compact = false,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  /// Builds from [LabelRegistry] — English primary, daily Hindi below.
  factory BilingualLabel.fromKey(
    String labelKey, {
    Key? key,
    TextStyle? englishStyle,
    TextStyle? hindiStyle,
    bool compact = false,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.start,
  }) {
    final pair = LabelRegistry.get(labelKey);
    return BilingualLabel(
      key: key,
      english: pair.english,
      hindi: pair.hindi,
      englishStyle: englishStyle,
      hindiStyle: hindiStyle,
      compact: compact,
      crossAxisAlignment: crossAxisAlignment,
    );
  }

  final String english;
  final String hindi;
  final TextStyle? englishStyle;
  final TextStyle? hindiStyle;
  final bool compact;
  final CrossAxisAlignment crossAxisAlignment;

  String get _hindiLine {
    final trimmed = hindi.trim();
    if (trimmed.startsWith('(') && trimmed.endsWith(')')) {
      return trimmed;
    }
    return '($trimmed)';
  }

  @override
  Widget build(BuildContext context) {
    final appText = context.appText;

    return Column(
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          english,
          style: englishStyle ??
              appText.primaryBold.copyWith(
                fontSize: compact ? 14 : 16,
                height: 1.2,
              ),
        ),
        SizedBox(height: compact ? 2 : 4),
        Text(
          _hindiLine,
          style: hindiStyle ??
              appText.hindi.copyWith(
                fontSize: compact ? 12 : 13,
              ),
        ),
      ],
    );
  }
}
