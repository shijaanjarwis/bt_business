import 'package:bt_business/core/errors/user_error_messages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/reminders/reminder_list_kind.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/widgets/branding/developer_footer.dart';
import '../../../../shared/widgets/feedback/app_error_view.dart';
import '../../../../shared/widgets/feedback/app_loading_view.dart';
import '../../../../shared/widgets/scaffold/app_register_app_bar.dart';
import '../providers/reminder_list_providers.dart';
import '../widgets/party_pending_entry_tile.dart';

/// Lists every pending transaction for one party (receivable or payable).
class PartyPendingDetailPage extends ConsumerWidget {
  const PartyPendingDetailPage({
    super.key,
    required this.kind,
    required this.partyId,
  });

  final ReminderListKind kind;
  final String partyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(
      partyPendingDetailProvider((kind: kind, partyId: partyId)),
    );

    return Scaffold(
      backgroundColor: ColorPalette.background,
      appBar: AppRegisterAppBar(
        english: kind.englishTitle,
        hindi: kind.hindiTitle,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: entriesAsync.when(
          loading: () => const AppLoadingView(),
          error: (error, _) => AppErrorView(
            title: 'Pending load nahi ho paya',
            message: UserErrorMessages.from(error),
            actionEnglish: 'Try Again',
            actionHindi: 'Phir Try Karein',
            onAction: () => ref.invalidate(
              partyPendingDetailProvider((kind: kind, partyId: partyId)),
            ),
          ),
          data: (entries) {
            if (entries.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                children: [
                  SizedBox(height: MediaQuery.sizeOf(context).height * 0.18),
                  Center(
                    child: Text(
                      kind.emptyMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        color: ColorPalette.labelSecondary,
                      ),
                    ),
                  ),
                  const DeveloperFooter(),
                ],
              );
            }

            final partyName = entries.first.partyName;
            final partyPhone = entries.first.partyPhone.trim();
            final total = entries.fold<double>(0, (sum, e) => sum + e.amount);

            return RefreshIndicator(
              color: ColorPalette.purple,
              onRefresh: () async {
                ref.invalidate(
                  partyPendingDetailProvider((kind: kind, partyId: partyId)),
                );
              },
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                itemCount: entries.length + 2,
                separatorBuilder: (context, index) {
                  if (index == 0 || index >= entries.length) {
                    return const SizedBox.shrink();
                  }
                  return const SizedBox(height: 10);
                },
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            partyName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: ColorPalette.labelPrimary,
                            ),
                          ),
                          if (partyPhone.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              partyPhone,
                              style: const TextStyle(
                                fontSize: 14,
                                color: ColorPalette.labelSecondary,
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Text(
                            '${entries.length} pending bills · Total ${CurrencyFormatter.format(total)}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: ColorPalette.purple,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  if (index == entries.length + 1) {
                    return const DeveloperFooter();
                  }
                  return PartyPendingEntryTile(entry: entries[index - 1]);
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
