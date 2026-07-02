import 'package:bt_business/core/router/route_names.dart';
import 'package:bt_business/features/business/presentation/providers/business_providers.dart';
import 'package:bt_business/features/splash/presentation/pages/splash_page.dart';
import 'package:bt_business/shared/widgets/branding/app_branding.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('splash shows branding copy and logo', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          businessGateProvider.overrideWith((ref) async => true),
        ],
        child: MaterialApp(
          home: const SplashPage(),
        ),
      ),
    );

    await tester.pump();
    expect(find.text(AppBranding.appName), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
    expect(find.text(AppBranding.splashTagline), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pump(AppBranding.splashDuration);
    await tester.pump(AppBranding.splashFadeDuration);
    await tester.pump();
  });

  testWidgets('splash navigates to dashboard when business exists', (tester) async {
    final router = GoRouter(
      initialLocation: RouteNames.splash,
      routes: [
        GoRoute(
          path: RouteNames.splash,
          builder: (context, state) => const SplashPage(),
        ),
        GoRoute(
          path: RouteNames.home,
          builder: (context, state) => const Scaffold(body: Text('Dashboard')),
        ),
        GoRoute(
          path: RouteNames.businessProfile,
          builder: (context, state) => const Scaffold(body: Text('Onboarding')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          businessGateProvider.overrideWith((ref) async => true),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    await tester.pump();
    await tester.pump(AppBranding.splashDuration);
    await tester.pump(AppBranding.splashFadeDuration);
    await tester.pumpAndSettle();

    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Onboarding'), findsNothing);
  });

  testWidgets('splash navigates to onboarding on first launch', (tester) async {
    final router = GoRouter(
      initialLocation: RouteNames.splash,
      routes: [
        GoRoute(
          path: RouteNames.splash,
          builder: (context, state) => const SplashPage(),
        ),
        GoRoute(
          path: RouteNames.home,
          builder: (context, state) => const Scaffold(body: Text('Dashboard')),
        ),
        GoRoute(
          path: RouteNames.businessProfile,
          builder: (context, state) => const Scaffold(body: Text('Onboarding')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          businessGateProvider.overrideWith((ref) async => false),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    await tester.pump();
    await tester.pump(AppBranding.splashDuration);
    await tester.pump(AppBranding.splashFadeDuration);
    await tester.pumpAndSettle();

    expect(find.text('Onboarding'), findsOneWidget);
    expect(find.text('Dashboard'), findsNothing);
  });
}
