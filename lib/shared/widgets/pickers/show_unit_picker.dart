import 'package:flutter/material.dart';

import '../../../core/constants/item_unit_library.dart';
import '../../../core/theme/color_palette.dart';

/// Searchable bottom sheet for the complete unit library.
Future<String?> showUnitPicker(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: ColorPalette.cardSurface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => const _UnitPickerSheet(),
  );
}

class _UnitPickerSheet extends StatefulWidget {
  const _UnitPickerSheet();

  @override
  State<_UnitPickerSheet> createState() => _UnitPickerSheetState();
}

class _UnitPickerSheetState extends State<_UnitPickerSheet> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ItemUnitEntry> get _results => ItemUnitLibrary.search(_query);

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.72,
        minChildSize: 0.45,
        maxChildSize: 0.92,
        builder: (context, scrollController) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: ColorPalette.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Unit Chuniye',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: ColorPalette.labelPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Search karein — Weight, Length, Count…',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: ColorPalette.labelSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _searchController,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Kg, Piece, Litre…',
                        prefixIcon: const Icon(Icons.search_rounded),
                        filled: true,
                        fillColor: ColorPalette.fieldFill,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (value) => setState(() => _query = value),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _results.isEmpty
                    ? _EmptyUnitSearch(
                        query: _query.trim(),
                        onUseCustom: _query.trim().isEmpty
                            ? null
                            : () => Navigator.pop(context, _query.trim()),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                        itemCount: _results.length,
                        itemBuilder: (context, index) {
                          final entry = _results[index];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              entry.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: ColorPalette.labelPrimary,
                              ),
                            ),
                            subtitle: Text(
                              entry.category,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: ColorPalette.labelSecondary,
                              ),
                            ),
                            trailing: const Icon(
                              Icons.chevron_right_rounded,
                              color: ColorPalette.iconPrimary,
                            ),
                            onTap: () =>
                                Navigator.pop(context, entry.name),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _EmptyUnitSearch extends StatelessWidget {
  const _EmptyUnitSearch({required this.query, this.onUseCustom});

  final String query;
  final VoidCallback? onUseCustom;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Unit nahi mila',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: ColorPalette.labelPrimary,
              ),
            ),
            if (onUseCustom != null) ...[
              const SizedBox(height: 12),
              FilledButton(
                onPressed: onUseCustom,
                child: Text('"$query" use karein'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
