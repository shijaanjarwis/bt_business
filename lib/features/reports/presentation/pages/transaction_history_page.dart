import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/color_palette.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../shared/widgets/feedback/app_error_view.dart';
import '../../../../shared/widgets/feedback/app_loading_view.dart';
import '../../../../shared/widgets/labels/bilingual_label.dart';
import '../../data/datasources/transaction_history_local_datasource.dart';
import '../../domain/history_models.dart';
import '../providers/history_providers.dart';

/// Full register history — all entries, filter by date.
class TransactionHistoryPage extends ConsumerWidget {
  const TransactionHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(transactionHistoryProvider);
    final period = ref.watch(historyPeriodProvider);

    return Scaffold(
      backgroundColor: ColorPalette.background,
      appBar: AppBar(
        backgroundColor: ColorPalette.background,
        elevation: 0,
        title: const BilingualLabel(
          english: 'History',
          hindi: 'Poora record',
          compact: true,
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: _PeriodFilterRow(period: period),
            ),
            if (period == HistoryPeriod.custom)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: _CustomDateRow(),
              ),
            Expanded(
              child: historyAsync.when(
                loading: () => const AppLoadingView(),
                error: (error, _) => AppErrorView(
                  title: 'Record load nahi ho paya',
                  message: error.toString(),
                  actionLabel: 'Try Again',
                  onAction: () => ref.invalidate(transactionHistoryProvider),
                ),
                data: (entries) {
                  if (entries.isEmpty) {
                    return const Center(
                      child: BilingualLabel(
                        english: 'No entries in this period',
                        hindi: 'Is samay koi entry nahi',
                      ),
                    );
                  }

                  return RefreshIndicator(
                    color: ColorPalette.purple,
                    onRefresh: () async => ref.invalidate(transactionHistoryProvider),
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                      itemCount: entries.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        return _HistoryTile(entry: entries[index]);
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
  }
}

class _PeriodFilterRow extends ConsumerWidget {
  const _PeriodFilterRow({required this.period});

  final HistoryPeriod period;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: HistoryPeriod.values.map((value) {
          final selected = period == value;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text('${value.hindiLabel} · ${value.englishLabel}'),
              selected: selected,
              onSelected: (_) {
                ref.read(historyPeriodProvider.notifier).state = value;
              },
              selectedColor: ColorPalette.purple.withValues(alpha: 0.15),
              checkmarkColor: ColorPalette.purple,
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _CustomDateRow extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final start = ref.watch(historyCustomStartProvider) ?? DateTime.now();
    final end = ref.watch(historyCustomEndProvider) ?? DateTime.now();

    Future<void> pickStart() async {
      final picked = await showDatePicker(
        context: context,
        initialDate: start,
        firstDate: DateTime(2000),
        lastDate: DateTime.now(),
      );
      if (picked != null) {
        ref.read(historyCustomStartProvider.notifier).state = picked;
      }
    }

    Future<void> pickEnd() async {
      final picked = await showDatePicker(
        context: context,
        initialDate: end,
        firstDate: DateTime(2000),
        lastDate: DateTime.now(),
      );
      if (picked != null) {
        ref.read(historyCustomEndProvider.notifier).state = picked;
      }
    }

    return Row(
      children: [
        Expanded(
          child: _DateChip(
            label: 'Se · From',
            date: start,
            onTap: pickStart,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _DateChip(
            label: 'Tak · To',
            date: end,
            onTap: pickEnd,
          ),
        ),
      ],
    );
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip({
    required this.label,
    required this.date,
    required this.onTap,
  });

  final String label;
  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF8E8E93))),
              const SizedBox(height: 4),
              Text(
                DateFormatter.shortDate(date),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.entry});

  final TransactionHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              DateFormatter.shortDate(entry.date),
              style: const TextStyle(fontSize: 12, color: Color(0xFF8E8E93)),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${entry.label} ${CurrencyFormatter.format(entry.amount)}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1C1C1E),
                  ),
                ),
                if (entry.partyName != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    entry.partyName!,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF636366)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
