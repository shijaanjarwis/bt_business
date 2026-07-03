import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/color_palette.dart';
import '../inputs/app_search_field.dart';
import '../labels/bilingual_label.dart';
import 'package:bt_business/core/errors/user_error_messages.dart';

/// Unified searchable picker bottom sheet — same search bar, spacing, and layout everywhere.
class AppSearchPickerSheet<T> extends ConsumerStatefulWidget {
  const AppSearchPickerSheet({
    super.key,
    required this.englishTitle,
    required this.hindiTitle,
    required this.watchItems,
    required this.itemBuilder,
    this.emptyEnglish = 'No results',
    this.emptyHindi = 'Kuch nahi mila',
    this.createLabelEnglish,
    this.createLabelHindi,
    this.onCreate,
  });

  final String englishTitle;
  final String hindiTitle;
  final AsyncValue<List<T>> Function(WidgetRef ref, String query) watchItems;
  final Widget Function(BuildContext context, T item, VoidCallback onSelect)
      itemBuilder;
  final String emptyEnglish;
  final String emptyHindi;
  final String? createLabelEnglish;
  final String? createLabelHindi;
  final Future<void> Function(String query)? onCreate;

  static Future<T?> show<T>({
    required BuildContext context,
    required String englishTitle,
    required String hindiTitle,
    required AsyncValue<List<T>> Function(WidgetRef ref, String query) watchItems,
    required Widget Function(BuildContext context, T item, VoidCallback onSelect)
        itemBuilder,
    String emptyEnglish = 'No results',
    String emptyHindi = 'Kuch nahi mila',
    String? createLabelEnglish,
    String? createLabelHindi,
    Future<void> Function(String query)? onCreate,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: ColorPalette.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => AppSearchPickerSheet<T>(
        englishTitle: englishTitle,
        hindiTitle: hindiTitle,
        watchItems: watchItems,
        itemBuilder: itemBuilder,
        emptyEnglish: emptyEnglish,
        emptyHindi: emptyHindi,
        createLabelEnglish: createLabelEnglish,
        createLabelHindi: createLabelHindi,
        onCreate: onCreate,
      ),
    );
  }

  @override
  ConsumerState<AppSearchPickerSheet<T>> createState() =>
      _AppSearchPickerSheetState<T>();
}

class _AppSearchPickerSheetState<T> extends ConsumerState<AppSearchPickerSheet<T>> {
  final _queryController = TextEditingController();

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  void _clearQuery() {
    _queryController.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final query = _queryController.text;
    final trimmed = query.trim();
    final itemsAsync = widget.watchItems(ref, query);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.78,
      minChildSize: 0.45,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
          ),
          child: Column(
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
              const SizedBox(height: AppSpacing.lg),
              BilingualLabel(
                english: widget.englishTitle,
                hindi: widget.hindiTitle,
                compact: true,
              ),
              const SizedBox(height: AppSpacing.md),
              AppSearchField(
                controller: _queryController,
                autofocus: true,
                onChanged: (_) => setState(() {}),
                onClear: _clearQuery,
              ),
              if (trimmed.isNotEmpty && widget.onCreate != null) ...[
                const SizedBox(height: AppSpacing.md),
                OutlinedButton.icon(
                  onPressed: () async {
                    await widget.onCreate!(trimmed);
                  },
                  icon: const Icon(Icons.add_rounded, color: ColorPalette.purple),
                  label: BilingualLabel(
                    english: widget.createLabelEnglish ?? 'Add "$trimmed"',
                    hindi: widget.createLabelHindi ?? 'Naya jodein',
                    compact: true,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: itemsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Center(
                    child: Text(
                      UserErrorMessages.from(error),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  data: (items) {
                    if (items.isEmpty) {
                      return Center(
                        child: BilingualLabel(
                          english: widget.emptyEnglish,
                          hindi: widget.emptyHindi,
                          compact: true,
                          crossAxisAlignment: CrossAxisAlignment.center,
                        ),
                      );
                    }

                    return ListView.separated(
                      controller: scrollController,
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return widget.itemBuilder(
                          context,
                          item,
                          () => Navigator.pop(context, item),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
