import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../shared/widgets/labels/bilingual_label.dart';
import '../../domain/entities/party.dart';

/// Large quick actions from a party's hisaab page.
class PartyQuickActions extends StatelessWidget {
  const PartyQuickActions({
    super.key,
    required this.party,
  });

  final Party party;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const BilingualLabel(
          english: 'Quick Actions',
          hindi: 'Jaldi Kaam',
          compact: true,
        ),
        const SizedBox(height: 12),
        _QuickActionButton(
          english: 'Sale',
          hindi: 'Bikri Likho',
          icon: Icons.edit_note_rounded,
          color: ColorPalette.purple,
          onTap: () => context.push('${RouteNames.salesNew}?partyId=${party.id}'),
        ),
        const SizedBox(height: 10),
        _QuickActionButton(
          english: 'Purchase',
          hindi: 'Maal Kharida',
          icon: Icons.shopping_bag_outlined,
          color: ColorPalette.accentBlue,
          onTap: () => context.push('${RouteNames.purchasesNew}?partyId=${party.id}'),
        ),
        const SizedBox(height: 10),
        _QuickActionButton(
          english: 'Cash Received',
          hindi: 'Paise Mile',
          icon: Icons.call_received_rounded,
          color: ColorPalette.accentGreen,
          onTap: () => context.push('${RouteNames.paymentsReceived}?partyId=${party.id}'),
        ),
        const SizedBox(height: 10),
        _QuickActionButton(
          english: 'Payment',
          hindi: 'Paise Diya',
          icon: Icons.call_made_rounded,
          color: ColorPalette.accentOrange,
          onTap: () => context.push('${RouteNames.paymentsPaid}?partyId=${party.id}'),
        ),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.english,
    required this.hindi,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String english;
  final String hindi;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ColorPalette.cardSurface,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: BilingualLabel(
                  english: english,
                  hindi: hindi,
                  compact: true,
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: color.withValues(alpha: 0.8)),
            ],
          ),
        ),
      ),
    );
  }
}
