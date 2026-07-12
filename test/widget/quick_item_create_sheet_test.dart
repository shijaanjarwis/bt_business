import 'package:bt_business/features/items/presentation/widgets/entry_item_picker_sheet.dart';
import 'package:bt_business/shared/widgets/buttons/app_primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('New Item sheet keeps Save button visible and tappable', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(390, 700)),
            child: Scaffold(
              body: Builder(
                builder: (context) {
                  return Center(
                    child: ElevatedButton(
                      onPressed: () {
                        showModalBottomSheet<void>(
                          context: context,
                          isScrollControlled: true,
                          useSafeArea: true,
                          builder: (context) => const QuickItemCreateSheet(
                            initialName: 'Test Maal',
                            mode: EntryItemMode.sale,
                          ),
                        );
                      },
                      child: const Text('Open'),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    final saveButton = find.byType(AppPrimaryButton);
    expect(saveButton, findsOneWidget);
    expect(tester.getRect(saveButton).bottom, lessThan(700));

    await tester.ensureVisible(saveButton);
    expect(tester.getRect(saveButton).height, greaterThan(0));
  });

  testWidgets('New Item sheet scrolls when keyboard reduces space', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(390, 700),
              viewInsets: EdgeInsets.only(bottom: 320),
            ),
            child: Scaffold(
              body: const QuickItemCreateSheet(
                initialName: 'Test Maal',
                mode: EntryItemMode.purchase,
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final saveButton = find.byType(AppPrimaryButton);
    expect(saveButton, findsOneWidget);
    expect(tester.getRect(saveButton).bottom, lessThan(700));
  });
}
