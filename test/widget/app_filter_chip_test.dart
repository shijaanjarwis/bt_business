import 'package:bt_business/core/theme/app_theme.dart';
import 'package:bt_business/core/theme/color_palette.dart';
import 'package:bt_business/shared/widgets/chips/app_filter_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('unselected filter chip uses light background in light mode', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: AppFilterChip(
            label: 'Today',
            selected: false,
            onSelected: () {},
          ),
        ),
      ),
    );

    final chip = tester.widget<FilterChip>(find.byType(FilterChip));
    expect(chip.backgroundColor, AppFilterChip.lightUnselectedBackground);
    expect(chip.surfaceTintColor, Colors.transparent);
    expect(chip.elevation, 0);
  });

  testWidgets('selected filter chip uses purple background in light mode', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: AppFilterChip(
            label: 'Today',
            selected: true,
            onSelected: () {},
          ),
        ),
      ),
    );

    final chip = tester.widget<FilterChip>(find.byType(FilterChip));
    expect(chip.selectedColor, ColorPalette.purple);
    expect(chip.surfaceTintColor, Colors.transparent);
    expect(find.text('Today'), findsOneWidget);
  });
}
