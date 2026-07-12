import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/color_palette.dart';
import '../../../features/payments/presentation/models/payment_register_filter.dart';
import '../../../features/payments/presentation/providers/payment_providers.dart';
import '../labels/bilingual_label.dart';
import '../sheets/app_bottom_sheet.dart';
import '../sheets/app_quick_entry_sheet.dart';
import '../../../features/voice/presentation/pages/voice_assistant_page.dart';

/// Resolves and handles global add + voice FAB actions for every main screen.
abstract final class GlobalFabManager {
  static const _mainPaths = {
    RouteNames.home,
    RouteNames.ledger,
    RouteNames.stock,
    RouteNames.sales,
    RouteNames.purchases,
    RouteNames.payments,
    RouteNames.history,
  };

  static bool shouldShow(String path) => _mainPaths.contains(_normalize(path));

  static void onPlusPressed(BuildContext context, WidgetRef ref) {
    switch (_screenFor(_normalize(GoRouterState.of(context).uri.path))) {
      case _FabScreen.dashboard:
      case _FabScreen.history:
        AppQuickEntrySheet.show(context);
      case _FabScreen.ledger:
        context.push(RouteNames.ledgerPartyNew);
      case _FabScreen.items:
        context.push(RouteNames.stockNew);
      case _FabScreen.sales:
        context.push(RouteNames.salesNew);
      case _FabScreen.purchases:
        context.push(RouteNames.purchasesNew);
      case _FabScreen.payments:
        _openPaymentEntry(context, ref);
      case null:
        break;
    }
  }

  static void onVoicePressed(BuildContext context, WidgetRef ref) {
    VoiceAssistantPage.open(context);
  }

  static String _normalize(String path) {
    if (path.length > 1 && path.endsWith('/')) {
      return path.substring(0, path.length - 1);
    }
    return path;
  }

  static _FabScreen? _screenFor(String path) {
    return switch (path) {
      RouteNames.home => _FabScreen.dashboard,
      RouteNames.ledger => _FabScreen.ledger,
      RouteNames.stock => _FabScreen.items,
      RouteNames.sales => _FabScreen.sales,
      RouteNames.purchases => _FabScreen.purchases,
      RouteNames.payments => _FabScreen.payments,
      RouteNames.history => _FabScreen.history,
      _ => null,
    };
  }

  static void _openPaymentEntry(BuildContext context, WidgetRef ref) {
    final filter = ref.read(paymentRegisterFilterProvider);
    switch (filter) {
      case PaymentRegisterFilter.received:
        context.push(RouteNames.paymentsReceived);
      case PaymentRegisterFilter.paid:
        context.push(RouteNames.paymentsPaid);
      case PaymentRegisterFilter.all:
        _showPaymentReceiveChoice(context);
    }
  }

  static Future<void> _showPaymentReceiveChoice(BuildContext context) {
    return showAppBottomSheet<void>(
      context: context,
      builder: (context) {
        return AppBottomSheetLayout(
          body: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const BilingualLabel(
                english: 'New Entry',
                hindi: 'Nayi Entry',
                compact: true,
              ),
              const SizedBox(height: AppSpacing.lg),
              _PaymentChoiceTile(
                english: 'Receive',
                hindi: 'Paise Mile',
                icon: Icons.call_received_rounded,
                onTap: () {
                  Navigator.pop(context);
                  context.push(RouteNames.paymentsReceived);
                },
              ),
              _PaymentChoiceTile(
                english: 'Payment',
                hindi: 'Paise Diye',
                icon: Icons.call_made_rounded,
                onTap: () {
                  Navigator.pop(context);
                  context.push(RouteNames.paymentsPaid);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

enum _FabScreen {
  dashboard,
  ledger,
  items,
  sales,
  purchases,
  payments,
  history,
}

class _PaymentChoiceTile extends StatelessWidget {
  const _PaymentChoiceTile({
    required this.english,
    required this.hindi,
    required this.icon,
    required this.onTap,
  });

  final String english;
  final String hindi;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: ColorPalette.background,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(icon, color: ColorPalette.iconPrimary),
                const SizedBox(width: 12),
                Expanded(
                  child: BilingualLabel(
                    english: english,
                    hindi: hindi,
                    compact: true,
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: ColorPalette.iconPrimary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
