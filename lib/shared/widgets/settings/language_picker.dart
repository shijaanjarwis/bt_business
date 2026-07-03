import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/assistant_language.dart';
import '../../../core/localization/language_provider.dart';
import '../../../core/theme/color_palette.dart';
import '../labels/app_form_field_label.dart';

/// Voice & greeting assistant language — does not change UI labels.
class AssistantLanguagePicker extends ConsumerWidget {
  const AssistantLanguagePicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(assistantLanguageProvider);
    final localization = ref.read(localizationServiceProvider);
    final helper = localization.helper(
      selected,
      'settings_assistant_helper',
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppFormFieldLabel(
          english: 'Voice & Greeting Language',
          hindi: 'Awaz aur Greeting',
          compact: true,
        ),
        const SizedBox(height: 8),
        ...AssistantLanguage.values.map(
          (language) => _AssistantLanguageTile(
            title: localization.assistantOptionTitle(language),
            subtitle: localization.assistantOptionSubtitle(language),
            selected: selected == language,
            enabled: language.selectable,
            onTap: language.selectable
                ? () => ref
                    .read(assistantLanguageProvider.notifier)
                    .setAssistantLanguage(language)
                : () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          localization.translate(
                            selected,
                            'assistant_coming_soon',
                          ),
                        ),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  },
          ),
        ),
        const SizedBox(height: 6),
        Text(
          helper,
          style: const TextStyle(
            fontSize: 12,
            color: ColorPalette.labelSecondary,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

/// @deprecated Use [AssistantLanguagePicker].
typedef LanguagePicker = AssistantLanguagePicker;

class _AssistantLanguageTile extends StatelessWidget {
  const _AssistantLanguageTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected
            ? ColorPalette.purple.withValues(alpha: 0.06)
            : ColorPalette.cardSurface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected
                    ? ColorPalette.purple.withValues(alpha: 0.35)
                    : Colors.black.withValues(alpha: 0.06),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: enabled
                              ? ColorPalette.labelPrimary
                              : ColorPalette.labelSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: enabled
                              ? ColorPalette.labelSecondary
                              : ColorPalette.labelSecondary
                                  .withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                if (selected)
                  const Icon(
                    Icons.check_circle_rounded,
                    color: ColorPalette.purple,
                    size: 22,
                  )
                else if (!enabled)
                  Text(
                    'Soon',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: ColorPalette.labelSecondary.withValues(alpha: 0.8),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
