import 'package:flutter/material.dart';

import '../../../core/theme/transaction_badge_theme.dart';

/// English-only colored transaction badge.
class AppTransactionBadge extends StatelessWidget {
  const AppTransactionBadge({
    super.key,
    required this.kind,
    this.compact = false,
  });

  final TransactionBadgeKind kind;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 5,
      ),
      decoration: BoxDecoration(
        color: kind.backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        kind.label,
        style: TextStyle(
          fontSize: compact ? 10 : 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
          color: kind.foregroundColor,
        ),
      ),
    );
  }
}
