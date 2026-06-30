import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/business/presentation/pages/business_profile_page.dart';
import '../../features/business/presentation/providers/business_providers.dart';
import '../../features/home/presentation/pages/home_dashboard_page.dart';
import '../../shared/widgets/navigation/main_shell.dart';
import '../../shared/widgets/scaffold/tab_placeholder_page.dart';
import '../../features/ledger/presentation/pages/ledger_page.dart';
import '../../features/ledger/presentation/pages/party_form_page.dart';
import 'router_error_page.dart';
import 'router_refresh_notifier.dart';
import 'route_names.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = ref.watch(routerRefreshNotifierProvider);
  final hasBusiness = ref.watch(businessGateProvider).valueOrNull;

  return GoRouter(
    initialLocation: RouteNames.home,
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final onProfileRoute = state.matchedLocation == RouteNames.businessProfile;

      if (hasBusiness == null) return null;
      if (!hasBusiness && !onProfileRoute) return RouteNames.businessProfile;
      return null;
    },
    errorBuilder: (context, state) => RouterErrorPage(state: state),
    routes: [
      GoRoute(
        path: RouteNames.businessProfile,
        name: RouteNames.businessProfileName,
        builder: (context, state) {
          final mode = state.uri.queryParameters['mode'] == 'edit'
              ? BusinessProfileMode.edit
              : BusinessProfileMode.setup;
          return BusinessProfilePage(mode: mode);
        },
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.home,
                name: RouteNames.homeName,
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: HomeDashboardPage(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.ledger,
                name: RouteNames.ledgerName,
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: LedgerPage(),
                ),
                routes: [
                  GoRoute(
                    path: 'party/new',
                    name: RouteNames.ledgerPartyNewName,
                    builder: (context, state) => const PartyFormPage(
                      mode: PartyFormMode.create,
                    ),
                  ),
                  GoRoute(
                    path: 'party/:id/edit',
                    name: RouteNames.ledgerPartyEditName,
                    builder: (context, state) => PartyFormPage(
                      mode: PartyFormMode.edit,
                      partyId: state.pathParameters['id'],
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.stock,
                name: RouteNames.stockName,
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: TabPlaceholderPage(
                    title: 'Stock',
                    subtitle: 'Maal ka record yahan hoga — jald aa raha hai',
                    icon: Icons.inventory_2_rounded,
                  ),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.reports,
                name: RouteNames.reportsName,
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: TabPlaceholderPage(
                    title: 'Reports',
                    subtitle: 'Business reports yahan milengi — jald aa raha hai',
                    icon: Icons.bar_chart_rounded,
                  ),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.ai,
                name: RouteNames.aiName,
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: TabPlaceholderPage(
                    title: 'AI',
                    subtitle: 'Smart business help yahan milegi — jald aa raha hai',
                    icon: Icons.auto_awesome_rounded,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
