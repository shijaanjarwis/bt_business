import 'package:bt_business/core/errors/user_error_messages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/widgets/branding/developer_footer.dart';
import '../../../../shared/widgets/feedback/app_error_view.dart';
import '../../../../shared/widgets/feedback/app_loading_view.dart';
import '../../../../shared/widgets/labels/bilingual_label.dart';
import '../../../../shared/widgets/scaffold/app_register_app_bar.dart';
import '../../domain/entities/party.dart';
import '../providers/party_providers.dart';
import '../utils/party_ledger_ui_helpers.dart';
import '../widgets/party_history_tile.dart';
import '../widgets/party_quick_actions.dart';

/// One party's full hisaab — balance, timeline, quick actions.
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
          title: 'Hisaab load nahi ho paya',
          message: UserErrorMessages.from(error),
          actionEnglish: 'Back', actionHindi: 'Wapas',
          onAction: () => context.pop(),
        ),
      ),
      data: (party) {
        if (party == null) {
          return Scaffold(
            body: AppErrorView(
              title: 'Party nahi mili',
              message: 'Yeh naam hisaab mein nahi mila.',
              actionEnglish: 'Back', actionHindi: 'Wapas',
              onAction: () => context.pop(),
            ),
          );
        }

        return Scaffold(
          backgroundColor: ColorPalette.background,
          appBar: AppRegisterAppBar(
            english: party.name,
            hindi: 'Party Hisaab',
            actions: [
              IconButton(
                tooltip: 'Edit',
                onPressed: () => context.push(RouteNames.ledgerPartyEditPath(partyId)),
                icon: const Icon(Icons.edit_outlined, color: ColorPalette.iconPrimary),
              ),
            ],
          ),
          body: SafeArea(
            child: historyAsync.when(
              loading: () => const AppLoadingView(),
              error: (error, _) => AppErrorView(
                title: 'History load nahi ho payi',
                message: UserErrorMessages.from(error),
                actionEnglish: 'Try Again', actionHindi: 'Phir Try Karein',
                onAction: () => ref.invalidate(partyHistoryProvider(partyId)),
              ),
              data: (entries) {
                final timeline = entries.reversed.toList();
                final stats = PartyLedgerUiHelpers.statsFrom(entries);

                return RefreshIndicator(
                  color: ColorPalette.purple,
                  onRefresh: () async {
                    ref.invalidate(partyHistoryProvider(partyId));
                    ref.invalidate(partyDetailProvider(partyId));
                  },
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    children: [
                      _PartyHeaderCard(
                        party: party,
                        onEdit: () => context.push(RouteNames.ledgerPartyEditPath(partyId)),
                      ),
                      const SizedBox(height: 12),
                      _PartyProfileSection(
                        party: party,
                        stats: stats,
                      ),
                      const SizedBox(height: 16),
                      PartyQuickActions(party: party),
                      const SizedBox(height: 20),
                      const BilingualLabel(
                        english: 'Full Ledger',
                        hindi: 'Poora Hisaab',
                        compact: true,
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Sabse nayi entry upar · tap karke badlein',
                        style: TextStyle(fontSize: 12, color: ColorPalette.labelSecondary),
                      ),
                      const SizedBox(height: 12),
                      if (timeline.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Center(
                            child: Text(
                              'Abhi koi entry nahi — upar se shuru karein',
                              style: TextStyle(color: ColorPalette.labelSecondary),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      else
                        ...timeline.map(
                          (entry) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: PartyHistoryTile(
                              entry: entry,
                              partyId: partyId,
                            ),
                          ),
                        ),
                      const DeveloperFooter(),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _PartyHeaderCard extends StatelessWidget {
  const _PartyHeaderCard({
    required this.party,
    required this.onEdit,
  });

  final Party party;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final status = PartyLedgerUiHelpers.balanceStatus(party);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      party.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: ColorPalette.labelPrimary,
                      ),
                    ),
                  ),
                  const Icon(Icons.edit_outlined, size: 20, color: ColorPalette.purple),
                ],
              ),
              if (party.phone.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  party.phone,
                  style: const TextStyle(
                    fontSize: 15,
                    color: ColorPalette.labelSecondary,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Text(
                status.label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: status.color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                PartyLedgerUiHelpers.formattedBalance(party),
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  color: status.color,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PartyProfileSection extends StatelessWidget {
  const _PartyProfileSection({
    required this.party,
    required this.stats,
  });

  final Party party;
  final PartyHistoryStats stats;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ColorPalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const BilingualLabel(
            english: 'Party Info',
            hindi: 'Party Ki Jaankari',
            compact: true,
          ),
          const SizedBox(height: 12),
          _ProfileRow(
            english: 'Address',
            hindi: 'Pata',
            value: party.address.trim().isEmpty ? '—' : party.address.trim(),
          ),
          if (party.gstin != null && party.gstin!.trim().isNotEmpty)
            _ProfileRow(
              english: 'GST',
              hindi: 'GST',
              value: party.gstin!.trim(),
            ),
          _ProfileRow(
            english: 'Opening Balance',
            hindi: 'Pehle se baaki',
            value: PartyLedgerUiHelpers.openingBalanceLabel(party),
          ),
          _ProfileRow(
            english: 'Current Balance',
            hindi: 'Ab ka hisaab',
            value: PartyLedgerUiHelpers.runningBalanceLabel(party.balance),
            valueColor: PartyLedgerUiHelpers.runningBalanceColor(party.balance),
          ),
          if (stats.lastEntry != null)
            _ProfileRow(
              english: 'Last Entry',
              hindi: 'Aakhri entry',
              value: PartyLedgerUiHelpers.lastTransactionLabel(stats.lastEntry!),
            ),
          const Divider(height: 24),
          _ProfileRow(
            english: 'Total Sale',
            hindi: 'Kul Bikri',
            value: CurrencyFormatter.format(stats.totalSale),
          ),
          _ProfileRow(
            english: 'Total Purchase',
            hindi: 'Kul Kharid',
            value: CurrencyFormatter.format(stats.totalPurchase),
          ),
          _ProfileRow(
            english: 'Total Received',
            hindi: 'Kul Jama',
            value: CurrencyFormatter.format(stats.totalReceived),
          ),
          _ProfileRow(
            english: 'Total Paid',
            hindi: 'Kul Paisa Diya',
            value: CurrencyFormatter.format(stats.totalPaid),
          ),
        ],
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
    required this.english,
    required this.hindi,
    required this.value,
    this.valueColor,
  });

  final String english;
  final String hindi;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: BilingualLabel(
              english: english,
              hindi: hindi,
              compact: true,
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: valueColor ?? ColorPalette.labelPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
