import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/widgets/feedback/app_error_view.dart';
import '../../../../shared/widgets/feedback/app_loading_view.dart';
import '../../../../shared/widgets/labels/bilingual_label.dart';
import '../../domain/entities/party.dart';
import '../providers/party_providers.dart';
import '../widgets/party_history_tile.dart';
import '../widgets/party_quick_actions.dart';

/// One person's page in the digital notebook — balance + full history.
class PartyDetailPage extends ConsumerWidget {
  const PartyDetailPage({
    super.key,
    required this.partyId,
  });

  final String partyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final partyAsync = ref.watch(partyDetailProvider(partyId));
    final historyAsync = ref.watch(partyHistoryProvider(partyId));

    return partyAsync.when(
      loading: () => const Scaffold(body: AppLoadingView()),
      error: (error, _) => Scaffold(
        body: AppErrorView(
          title: 'Load nahi ho paya',
          message: error.toString(),
          actionLabel: 'Back',
          onAction: () => context.pop(),
        ),
      ),
      data: (party) {
        if (party == null) {
          return Scaffold(
            body: AppErrorView(
              title: 'Not found',
              message: 'Yeh naam hisaab mein nahi mila.',
              actionLabel: 'Back',
              onAction: () => context.pop(),
            ),
          );
        }

        return Scaffold(
          backgroundColor: ColorPalette.background,
          appBar: AppBar(
            backgroundColor: ColorPalette.background,
            elevation: 0,
            title: Text(party.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => context.push(RouteNames.ledgerPartyEditPath(partyId)),
              ),
            ],
          ),
          bottomNavigationBar: PartyQuickActions(party: party),
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _BalanceHeader(party: party),
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: BilingualLabel(
                    english: 'History',
                    hindi: 'Poora hisaab',
                    compact: true,
                  ),
                ),
                Expanded(
                  child: historyAsync.when(
                    loading: () => const AppLoadingView(),
                    error: (error, _) => AppErrorView(
                      title: 'History load nahi ho payi',
                      message: error.toString(),
                      actionLabel: 'Try Again',
                      onAction: () => ref.invalidate(partyHistoryProvider(partyId)),
                    ),
                    data: (entries) {
                      if (entries.isEmpty) {
                        return const Center(
                          child: BilingualLabel(
                            english: 'No entries yet',
                            hindi: 'Upar Sale ya Received dabayein',
                          ),
                        );
                      }

                      return RefreshIndicator(
                        color: ColorPalette.purple,
                        onRefresh: () async {
                          ref.invalidate(partyHistoryProvider(partyId));
                          ref.invalidate(partyDetailProvider(partyId));
                        },
                        child: ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics(),
                          ),
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                          itemCount: entries.length,
                          separatorBuilder: (_, _) => const PartyHistoryDivider(),
                          itemBuilder: (context, index) {
                            return PartyHistoryTile(entry: entries[index]);
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BalanceHeader extends StatelessWidget {
  const _BalanceHeader({required this.party});

  final Party party;

  @override
  Widget build(BuildContext context) {
    final balance = party.balance.abs();
    final isClear = balance == 0;
    final isLena = party.isReceivable;

    final label = isClear
        ? 'Sab clear'
        : isLena
            ? 'Lena Hai'
            : 'Dena Hai';
    final color = isClear
        ? const Color(0xFF8E8E93)
        : isLena
            ? const Color(0xFF34C759)
            : const Color(0xFFFF3B30);

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          if (party.phone.isNotEmpty)
            Text(
              party.phone,
              style: const TextStyle(color: Color(0xFF636366)),
            ),
          if (party.phone.isNotEmpty) const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            CurrencyFormatter.format(balance),
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}
