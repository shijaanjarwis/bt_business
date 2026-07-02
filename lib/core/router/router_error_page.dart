import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../shared/widgets/feedback/app_error_view.dart';
import 'route_names.dart';

/// Builds the route-not-found screen for [GoRouter.errorBuilder].
class RouterErrorPage extends StatelessWidget {
  const RouterErrorPage({
    super.key,
    required this.state,
  });

  final GoRouterState state;

  @override
  Widget build(BuildContext context) {
    return AppErrorView(
      title: 'Page not found',
      message: state.uri.toString(),
      actionEnglish: 'Home', actionHindi: 'Ghar Jayein',
      onAction: () => context.go(RouteNames.home),
    );
  }
}
