import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../shared/widgets/labels/bilingual_label.dart';

/// Hub for jama and kharch register entries.
class PaymentsHubPage extends StatelessWidget {
  const PaymentsHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorPalette.background,
      appBar: AppBar(
        backgroundColor: ColorPalette.background,
        elevation: 0,
        title: const BilingualLabel(
          english: 'Jama',
          hindi: 'Jama aur kharch likho',
          compact: true,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _EntryCard(
                icon: Icons.call_received_rounded,
                color: const Color(0xFF34C759),
                english: 'Jama',
                hindi: 'Paisa mila',
                onTap: () => context.push(RouteNames.paymentsReceived),
              ),
              const SizedBox(height: 12),
              _EntryCard(
                icon: Icons.call_made_rounded,
                color: Colors.orange.shade700,
                english: 'Paise Diye',
                hindi: 'Paisa diya',
                onTap: () => context.push(RouteNames.paymentsPaid),
              ),
              const SizedBox(height: 12),
              _EntryCard(
                icon: Icons.receipt_long_rounded,
                color: ColorPalette.purple,
                english: 'Kharch',
                hindi: 'Diesel, chai, rent…',
                onTap: () => context.push(RouteNames.paymentsExpense),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EntryCard extends StatelessWidget {
  const _EntryCard({
    required this.icon,
    required this.color,
    required this.english,
    required this.hindi,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String english;
  final String hindi;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: BilingualLabel(
                  english: english,
                  hindi: hindi,
                  compact: true,
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: color),
            ],
          ),
        ),
      ),
    );
  }
}
