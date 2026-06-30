import 'package:bt_business/features/business/presentation/pages/business_profile_page.dart';
import 'package:bt_business/features/business/presentation/providers/business_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Business profile setup form renders required fields', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          businessProfileProvider.overrideWith((ref) async => null),
        ],
        child: const MaterialApp(
          home: BusinessProfilePage(mode: BusinessProfileMode.setup),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Set Up Business'), findsOneWidget);
    expect(find.text('Business Name'), findsOneWidget);
    expect(find.text('GSTIN (optional)'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pumpAndSettle();

    expect(find.text('Financial Year Starts'), findsOneWidget);
    expect(find.text('Currency'), findsOneWidget);
    expect(find.text('Save & Continue'), findsOneWidget);
  });
}
