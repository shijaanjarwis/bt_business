import 'package:flutter/material.dart';

import '../accounting/transaction_types.dart';

/// English-only transaction badge styles — never show Hindi inside badges.
enum TransactionBadgeKind {
  sale,
  purchase,
  payment,
  receive,
  expense,
  stock,
  other;

  String get label => switch (this) {
        sale => 'SALE',
        purchase => 'PURCHASE',
        payment => 'PAYMENT',
        receive => 'RECEIVE',
        expense => 'EXPENSE',
        stock => 'STOCK',
        other => 'ENTRY',
      };

  Color get backgroundColor => switch (this) {
        sale => const Color(0xFFD6EAFF),
        purchase => const Color(0xFFFFF3CD),
        payment => const Color(0xFFFFE5E5),
        receive => const Color(0xFFE8F8ED),
        expense => const Color(0xFFE5E5EA),
        stock => const Color(0xFFE8E8ED),
        other => const Color(0xFFE5E5EA),
      };

  Color get foregroundColor => switch (this) {
        sale => const Color(0xFF0055B3),
        purchase => const Color(0xFF8B6914),
        payment => const Color(0xFFB3261E),
        receive => const Color(0xFF1B7A3D),
        expense => const Color(0xFF48484A),
        stock => const Color(0xFF48484A),
        other => const Color(0xFF48484A),
      };

  static TransactionBadgeKind fromTransactionType(String type) {
    return switch (type) {
      TransactionTypes.sale => sale,
      TransactionTypes.purchase => purchase,
      TransactionTypes.paymentPaid => payment,
      TransactionTypes.paymentReceived => receive,
      TransactionTypes.expense => expense,
      'party_created' || 'party_updated' => other,
      _ => other,
    };
  }
}
