import 'package:bt_business/features/items/presentation/widgets/entry_item_picker_sheet.dart';
import 'package:bt_business/features/sales/presentation/widgets/entry_party_picker_sheet.dart';
import 'package:bt_business/shared/widgets/buttons/app_primary_button.dart';
import 'package:bt_business/shared/widgets/sheets/app_bottom_sheet.dart';
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
                        showAppBottomSheet<void>(
                          context: context,
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

  testWidgets('New Party sheet keeps Save button visible and tappable', (tester) async {
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
                        showAppBottomSheet<void>(
                          context: context,
                          builder: (context) => const QuickPartyCreateSheet(
                            initialName: 'Test Party',
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

  testWidgets('New Party sheet keeps Save visible when keyboard is open', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(390, 700),
              viewInsets: EdgeInsets.only(bottom: 320),
            ),
            child: Scaffold(
              body: const QuickPartyCreateSheet(initialName: 'Test Party'),
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
