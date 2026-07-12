import 'package:flutter/scheduler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../logging/startup_trace.dart';
import '../reminders/reminder_list_kind.dart';
import '../../features/home/presentation/models/dashboard_summary_kind.dart';
import '../../features/backup/presentation/pages/data_safety_page.dart';
import '../../features/business/presentation/pages/business_profile_page.dart';
import '../../features/business/presentation/providers/business_providers.dart';
import '../../features/home/presentation/pages/dashboard_summary_detail_page.dart';
import '../../features/home/presentation/pages/party_pending_detail_page.dart';
import '../../features/home/presentation/pages/reminder_list_page.dart';
import '../../features/home/presentation/pages/home_dashboard_page.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import '../../shared/widgets/navigation/main_shell.dart';
import '../../features/items/presentation/pages/item_form_page.dart';
import '../../features/items/presentation/pages/item_list_page.dart';
import '../../features/ledger/presentation/pages/ledger_page.dart';
import '../../features/ledger/presentation/pages/party_detail_page.dart';
import '../../features/ledger/presentation/pages/party_form_page.dart';
import '../../features/sales/presentation/pages/sale_detail_page.dart';
import '../../features/sales/presentation/pages/sale_form_page.dart';
import '../../features/sales/presentation/pages/sale_list_page.dart';
import '../../features/payments/presentation/pages/expense_form_page.dart';
import '../../features/payments/presentation/pages/payment_detail_page.dart';
import '../../features/payments/presentation/pages/payment_form_page.dart';
import '../../features/payments/presentation/pages/payment_register_page.dart';
import '../../features/purchase/presentation/pages/purchase_detail_page.dart';
import '../../features/purchase/presentation/pages/purchase_form_page.dart';
import '../../features/purchase/presentation/pages/purchase_list_page.dart';
import '../../features/reports/presentation/pages/transaction_history_page.dart';
import '../../shared/widgets/feedback/app_error_view.dart';
import '../../shared/widgets/scaffold/keep_alive_tab.dart';
import 'router_error_page.dart';
import 'router_refresh_notifier.dart';
import 'route_names.dart';

/// Root navigator for notification taps and deep links.
final rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  StartupTrace.logOnce('START router provider');
  final refreshNotifier = ref.watch(routerRefreshNotifierProvider);

  // Defer refresh so GoRouter is never re-entered synchronously during redirect.
  ref.listen<AsyncValue<bool>>(businessGateProvider, (_, _) {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      refreshNotifier.refresh();
    });
  });

  final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: RouteNames.splash,
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final onSplash = state.matchedLocation == RouteNames.splash;
      if (onSplash) return null;

      final gate = ref.read(businessGateProvider);
      final onProfileRoute = state.matchedLocation == RouteNames.businessProfile;
      final isEditProfile = state.uri.queryParameters['mode'] == 'edit';

      // Splash owns startup; never redirect back to splash while gate loads.
      if (gate.isLoading) {
        return null;
      }

      final hasBusiness = gate.valueOrNull ?? false;
      if (!hasBusiness) {
        return onProfileRoute ? null : RouteNames.businessProfile;
      }

      if (onProfileRoute && !isEditProfile) {
        return RouteNames.home;
      }

      return null;
    },
    errorBuilder: (context, state) => RouterErrorPage(state: state),
    routes: [
      GoRoute(
        path: RouteNames.splash,
        name: RouteNames.splashName,
        pageBuilder: (context, state) => const NoTransitionPage(
          child: SplashPage(),
        ),
      ),
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
      GoRoute(
        path: RouteNames.dataSafety,
        name: RouteNames.dataSafetyName,
        builder: (context, state) => const DataSafetyPage(),
      ),
      GoRoute(
        path: RouteNames.backup,
        name: RouteNames.backupName,
        redirect: (context, state) => RouteNames.dataSafety,
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
                  child: KeepAliveTab(child: HomeDashboardPage()),
                ),
                routes: [
                  GoRoute(
                    path: 'payments',
                    name: RouteNames.paymentsName,
                    builder: (context, state) => const PaymentRegisterPage(),
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
                      GoRoute(
                        path: ':id/edit',
                        name: RouteNames.paymentsEditName,
                        builder: (context, state) => PaymentFormPage(
                          mode: PaymentFormMode.received,
                          paymentId: state.pathParameters['id'],
                        ),
                      ),
                      GoRoute(
                        path: ':id',
                        name: RouteNames.paymentsDetailName,
                        builder: (context, state) => PaymentDetailPage(
                          paymentId: state.pathParameters['id']!,
                        ),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'history',
                    name: RouteNames.historyName,
                    builder: (context, state) => const TransactionHistoryPage(),
                  ),
                  GoRoute(
                    path: 'reminders/:kind',
                    name: RouteNames.reminderListName,
                    builder: (context, state) {
                      final kind = ReminderListKind.fromRoute(
                        state.pathParameters['kind']!,
                      );
                      if (kind == null) {
                        return AppErrorView(
                          title: 'Page not found',
                          message: 'Yeh reminder page available nahi hai.',
                          actionEnglish: 'Back',
                          actionHindi: 'Wapas',
                          onAction: () => context.pop(),
                        );
                      }
                      return ReminderListPage(kind: kind);
                    },
                    routes: [
                      GoRoute(
                        path: 'party/:partyId',
                        name: RouteNames.partyPendingDetailName,
                        builder: (context, state) {
                          final kind = ReminderListKind.fromRoute(
                            state.pathParameters['kind']!,
                          );
                          final partyId = state.pathParameters['partyId'];
                          if (kind == null ||
                              partyId == null ||
                              !kind.groupsByParty) {
                            return AppErrorView(
                              title: 'Page not found',
                              message: 'Yeh pending page available nahi hai.',
                              actionEnglish: 'Back',
                              actionHindi: 'Wapas',
                              onAction: () => context.pop(),
                            );
                          }
                          return PartyPendingDetailPage(
                            kind: kind,
                            partyId: partyId,
                          );
                        },
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'summary/:kind',
                    name: RouteNames.dashboardSummaryDetailName,
                    builder: (context, state) {
                      final kind = DashboardSummaryKind.fromRoute(
                        state.pathParameters['kind']!,
                      );
                      if (kind == null) {
                        return AppErrorView(
                          title: 'Page not found',
                          message: 'Yeh summary page available nahi hai.',
                          actionEnglish: 'Back',
                          actionHindi: 'Wapas',
                          onAction: () => context.pop(),
                        );
                      }
                      return DashboardSummaryDetailPage(kind: kind);
                    },
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
                  child: KeepAliveTab(child: LedgerPage()),
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
                  child: KeepAliveTab(child: ItemListPage()),
                ),
                routes: [
                  GoRoute(
                    path: 'new',
                    name: RouteNames.stockNewName,
                    builder: (context, state) => const ItemFormPage(
                      mode: ItemFormMode.create,
                    ),
                  ),
                  GoRoute(
                    path: ':id/edit',
                    name: RouteNames.stockEditName,
                    builder: (context, state) => ItemFormPage(
                      mode: ItemFormMode.edit,
                      itemId: state.pathParameters['id'],
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.sales,
                name: RouteNames.salesName,
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: KeepAliveTab(child: SaleListPage()),
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
                  GoRoute(
                    path: ':id',
                    name: RouteNames.salesDetailName,
                    builder: (context, state) => SaleDetailPage(
                      saleId: state.pathParameters['id']!,
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
                  child: KeepAliveTab(child: PurchaseListPage()),
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
                  GoRoute(
                    path: ':id',
                    name: RouteNames.purchasesDetailName,
                    builder: (context, state) => PurchaseDetailPage(
                      purchaseId: state.pathParameters['id']!,
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

  ref.onDispose(router.dispose);
  return router;
});
