import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bt_business/app.dart';
import 'package:bt_business/features/business/presentation/providers/business_providers.dart';

void main() {
  testWidgets('Home dashboard renders with branding and bilingual labels',
      (tester) async {
    await tester.pumpWidget(
      TickerMode(
        enabled: false,
        child: ProviderScope(
          overrides: [
            businessGateProvider.overrideWith((ref) async => true),
          ],
          child: const BtBusinessApp(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.text('BT Business'), findsOneWidget);
    expect(
      find.text('Bharat Traders - Your Smart Business Partner'),
      findsOneWidget,
    );
    expect(find.text("Today's Profit"), findsOneWidget);
    expect(find.text('(Aaj Ka Profit)'), findsOneWidget);
    expect(find.text("Today's Sales"), findsOneWidget);
    expect(find.text('(Aaj Ki Sale)'), findsOneWidget);
    expect(find.text('Voice'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Ledger'), findsOneWidget);
    expect(find.text('Stock'), findsOneWidget);
    expect(find.text('Reports'), findsOneWidget);
    expect(find.text('AI'), findsOneWidget);
  });
}
