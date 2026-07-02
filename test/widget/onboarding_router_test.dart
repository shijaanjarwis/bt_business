import 'package:bt_business/app.dart';
import 'package:bt_business/features/business/presentation/providers/business_providers.dart';
import 'package:bt_business/shared/widgets/branding/app_branding.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('onboarding gate routes to setup form without hanging', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          businessGateProvider.overrideWith((ref) async => false),
          businessProfileProvider.overrideWith((ref) async => null),
        ],
        child: const TickerMode(
          enabled: false,
          child: BtBusinessApp(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(AppBranding.splashDuration);
    await tester.pump(AppBranding.splashFadeDuration);
    await tester.pumpAndSettle();

    expect(find.text('Set Up Business'), findsOneWidget);
    expect(find.text('(Dukaan Setup)'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Continue'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Continue'), findsOneWidget);
    expect(find.text('(Aage Badhein)'), findsOneWidget);
  });
}
