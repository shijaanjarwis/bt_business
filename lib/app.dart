import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/logging/startup_trace.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'shared/widgets/layout/dismiss_keyboard.dart';

/// Root application widget — Material 3, iPhone-first, Go Router.
class BtBusinessApp extends ConsumerWidget {
  const BtBusinessApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    StartupTrace.logOnce('START router widget tree');

    return MaterialApp.router(
      title: 'BT Business',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      builder: (context, child) =>
          DismissKeyboard(child: child ?? const SizedBox.shrink()),
      routerConfig: router,
    );
  }
}
