import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/utils/register_date_period.dart';
import '../../../payments/presentation/models/payment_register_filter.dart';
import '../../../payments/presentation/providers/payment_providers.dart';
import '../../../sales/presentation/models/sale_register_filter.dart';
import '../../../sales/presentation/providers/sale_providers.dart';
import '../models/dashboard_metric.dart';

/// Opens the matching register tab with dashboard card filters applied.
abstract final class DashboardRegisterNavigation {
  static void open(BuildContext context, WidgetRef ref, DashboardMetric metric) {
    final range = RegisterDateRange.resolve(period: RegisterDatePeriod.today);

    switch (metric.target) {
      case DashboardMetricTarget.todaySales:
        ref.read(saleRegisterDatePeriodProvider.notifier).state =
            RegisterDatePeriod.today;
        ref.read(saleRegisterCustomStartProvider.notifier).state = range.start;
        ref.read(saleRegisterCustomEndProvider.notifier).state = range.end;
        ref.read(saleRegisterFilterProvider.notifier).state = SaleRegisterFilter.all;
        context.go(RouteNames.sales);
      case DashboardMetricTarget.todayCash:
        ref.read(paymentRegisterDatePeriodProvider.notifier).state =
            RegisterDatePeriod.today;
        ref.read(paymentRegisterCustomStartProvider.notifier).state = range.start;
        ref.read(paymentRegisterCustomEndProvider.notifier).state = range.end;
        ref.read(paymentRegisterFilterProvider.notifier).state =
            PaymentRegisterFilter.received;
        context.go(RouteNames.payments);
      case DashboardMetricTarget.todayCredit:
        ref.read(saleRegisterDatePeriodProvider.notifier).state =
            RegisterDatePeriod.today;
        ref.read(saleRegisterCustomStartProvider.notifier).state = range.start;
        ref.read(saleRegisterCustomEndProvider.notifier).state = range.end;
        ref.read(saleRegisterFilterProvider.notifier).state =
            SaleRegisterFilter.hasBalance;
        context.go(RouteNames.sales);
      case DashboardMetricTarget.cashInHand:
        ref.read(paymentRegisterDatePeriodProvider.notifier).state =
            RegisterDatePeriod.thisMonth;
        ref.read(paymentRegisterFilterProvider.notifier).state =
            PaymentRegisterFilter.all;
        context.go(RouteNames.payments);
    }
  }
}
