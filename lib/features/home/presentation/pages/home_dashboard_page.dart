import 'package:bt_business/core/errors/user_error_messages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/logging/startup_trace.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../shared/widgets/branding/developer_footer.dart';
import '../../../../shared/widgets/layout/main_shell_insets.dart';
import '../../../../shared/widgets/feedback/app_error_view.dart';
import '../../../../shared/widgets/feedback/app_loading_view.dart';
import '../../../business/presentation/providers/business_providers.dart';
import '../../../items/domain/entities/item.dart';
import '../../../reports/data/datasources/transaction_history_local_datasource.dart';
import '../models/dashboard_metric.dart';
import '../models/dashboard_metrics_builder.dart';
import '../providers/dashboard_extras_provider.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/dashboard_low_stock_section.dart';
import '../widgets/dashboard_quick_actions.dart';
import '../widgets/dashboard_recent_activity_section.dart';
import '../widgets/dashboard_reminder_summary_section.dart';
import '../widgets/dashboard_reminders_section.dart';
import '../widgets/dashboard_summary_grid.dart';
import '../widgets/dashboard_backup_banner.dart';
import '../widgets/notification_permission_banner.dart';
import '../../../../core/reminders/reminder_models.dart';
import '../../../../core/reminders/reminder_providers.dart';

/// Daily business overview for shopkeepers and wholesalers.
class HomeDashboardPage extends ConsumerWidget {
  const HomeDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    StartupTrace.logOnce('START dashboard');
    final dashboardAsync = ref.watch(dashboardProvider);
    final businessAsync = ref.watch(businessProfileProvider);
    final recentAsync = ref.watch(dashboardRecentActivityProvider);
    final lowStockAsync = ref.watch(dashboardLowStockProvider);
    final remindersAsync = ref.watch(dashboardDueRemindersProvider);
    final reminderSummaryAsync = ref.watch(reminderSummaryProvider);

    return Scaffold(
      backgroundColor: ColorPalette.background,
      body: dashboardAsync.when(
        loading: () => const AppLoadingView(),
        error: (error, _) => AppErrorView(
          title: 'Dashboard load nahi ho paya',
          message: UserErrorMessages.from(error),
          actionEnglish: 'Try Again', actionHindi: 'Phir Try Karein',
          onAction: () => ref.invalidate(dashboardProvider),
          icon: Icons.cloud_off_rounded,
        ),
        data: (summary) {
          final businessName = businessAsync.maybeWhen(
            data: (business) => business?.name.trim().isNotEmpty == true
                ? business!.name
                : 'Apka Business',
            orElse: () => 'Apka Business',
          );
          final metrics = DashboardMetricsBuilder.fromSummary(summary);
          final recentEntries = recentAsync.valueOrNull ?? const [];
          final lowStockItems = lowStockAsync.valueOrNull ?? const [];
          final dueReminders = remindersAsync.valueOrNull ?? const [];
          final reminderSummary =
              reminderSummaryAsync.valueOrNull ?? ReminderDashboardSummary.zero;

          return _DashboardContent(
            businessName: businessName,
            metrics: metrics,
            recentEntries: recentEntries,
            lowStockItems: lowStockItems,
            dueReminders: dueReminders,
            reminderSummary: reminderSummary,
            onRefresh: () async {
              ref.invalidate(dashboardProvider);
              ref.invalidate(dashboardRecentActivityProvider);
              ref.invalidate(dashboardLowStockProvider);
              ref.invalidate(dashboardDueRemindersProvider);
              ref.invalidate(reminderSummaryProvider);
              ref.invalidate(businessProfileProvider);
              await ref.read(dashboardProvider.future);
            },
            onProfileTap: () => context.push(
              '${RouteNames.businessProfile}?mode=edit',
            ),
          );
        },
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({
    required this.businessName,
    required this.metrics,
    required this.recentEntries,
    required this.lowStockItems,
    required this.dueReminders,
    required this.reminderSummary,
    required this.onRefresh,
    required this.onProfileTap,
  });

  final String businessName;
  final List<DashboardMetric> metrics;
  final List<TransactionHistoryEntry> recentEntries;
  final List<Item> lowStockItems;
  final List<ReminderEntry> dueReminders;
  final ReminderDashboardSummary reminderSummary;
  final Future<void> Function() onRefresh;
  final VoidCallback onProfileTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        color: ColorPalette.purple,
        onRefresh: onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: EdgeInsets.fromLTRB(
            AppDimensions.screenPaddingH,
            AppSpacing.sm,
            AppDimensions.screenPaddingH,
            MainShellInsets.scrollBottomWithFab(context),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DashboardHeader(
                businessName: businessName,
                onProfileTap: onProfileTap,
              ),
              const SizedBox(height: AppSpacing.md),
              const NotificationPermissionBanner(),
              const SizedBox(height: AppSpacing.md),
              const DashboardBackupBanner(),
              const SizedBox(height: AppSpacing.xxl),
              DashboardSummaryGrid(metrics: metrics),
              if (dueReminders.isNotEmpty || reminderSummary.hasData) ...[
                const SizedBox(height: AppSpacing.xxl),
                DashboardReminderSummarySection(summary: reminderSummary),
              ],
              if (dueReminders.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xxl),
                DashboardRemindersSection(reminders: dueReminders),
              ],
              const SizedBox(height: AppSpacing.xxl),
              const DashboardQuickActions(),
              if (lowStockItems.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xxl),
                DashboardLowStockSection(items: lowStockItems),
              ],
              const SizedBox(height: AppSpacing.xxl),
              DashboardRecentActivitySection(entries: recentEntries),
              const DeveloperFooter(
                padding: EdgeInsets.fromLTRB(0, 28, 0, 8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
