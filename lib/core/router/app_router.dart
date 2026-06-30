import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/business/presentation/pages/business_profile_page.dart';
import '../../features/business/presentation/providers/business_providers.dart';
import '../../features/home/presentation/pages/home_dashboard_page.dart';
import '../../shared/widgets/navigation/main_shell.dart';
import '../../features/items/presentation/pages/item_list_page.dart';
import '../../features/ledger/presentation/pages/ledger_page.dart';
import '../../features/ledger/presentation/pages/party_detail_page.dart';
import '../../features/ledger/presentation/pages/party_form_page.dart';
import '../../features/sales/presentation/pages/sale_form_page.dart';
import '../../features/sales/presentation/pages/sale_list_page.dart';
import '../../features/payments/presentation/pages/expense_form_page.dart';
import '../../features/payments/presentation/pages/payment_form_page.dart';
import '../../features/payments/presentation/pages/payments_hub_page.dart';
import '../../features/purchase/presentation/pages/purchase_form_page.dart';
import '../../features/purchase/presentation/pages/purchase_list_page.dart';
import '../../features/reports/presentation/pages/transaction_history_page.dart';
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
                routes: [
                  GoRoute(
                    path: 'payments',
                    name: RouteNames.paymentsName,
                    builder: (context, state) => const PaymentsHubPage(),
                    routes: [
                      GoRoute(
                        path: 'received',
                        name: RouteNames.paymentsReceivedName,
                        builder: (context, state) => PaymentFormPage(
                          mode: PaymentFormMode.received,
                          initialPartyId: state.uri.queryParameters['partyId'],
                        ),
                      ),
                      GoRoute(
                        path: 'paid',
                        name: RouteNames.paymentsPaidName,
                        builder: (context, state) => PaymentFormPage(
                          mode: PaymentFormMode.paid,
                          initialPartyId: state.uri.queryParameters['partyId'],
                        ),
                      ),
                      GoRoute(
                        path: 'expense',
                        name: RouteNames.paymentsExpenseName,
                        builder: (context, state) => const ExpenseFormPage(),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'history',
                    name: RouteNames.historyName,
                    builder: (context, state) => const TransactionHistoryPage(),
                  ),
                ],
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
                    path: 'party/:id',
                    name: RouteNames.ledgerPartyDetailName,
                    builder: (context, state) => PartyDetailPage(
                      partyId: state.pathParameters['id']!,
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
                  child: ItemListPage(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.sales,
                name: RouteNames.salesName,
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: SaleListPage(),
                ),
                routes: [
                  GoRoute(
                    path: 'new',
                    name: RouteNames.salesNewName,
                    builder: (context, state) => SaleFormPage(
                      mode: SaleFormMode.create,
                      initialPartyId: state.uri.queryParameters['partyId'],
                    ),
                  ),
                  GoRoute(
                    path: ':id/edit',
                    name: RouteNames.salesEditName,
                    builder: (context, state) => SaleFormPage(
                      mode: SaleFormMode.edit,
                      saleId: state.pathParameters['id'],
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.purchases,
                name: RouteNames.purchasesName,
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: PurchaseListPage(),
                ),
                routes: [
                  GoRoute(
                    path: 'new',
                    name: RouteNames.purchasesNewName,
                    builder: (context, state) => PurchaseFormPage(
                      mode: PurchaseFormMode.create,
                      initialPartyId: state.uri.queryParameters['partyId'],
                    ),
                  ),
                  GoRoute(
                    path: ':id/edit',
                    name: RouteNames.purchasesEditName,
                    builder: (context, state) => PurchaseFormPage(
                      mode: PurchaseFormMode.edit,
                      purchaseId: state.pathParameters['id'],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
