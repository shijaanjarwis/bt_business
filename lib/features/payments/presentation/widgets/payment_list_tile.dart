import 'package:flutter/material.dart';

import '../../../../shared/widgets/register/register_entry_cards.dart';
import '../../../sales/presentation/providers/sale_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/payment_register_entry.dart';

class PaymentListTile extends ConsumerWidget {
  const PaymentListTile({
    super.key,
    required this.entry,
    required this.onTap,
  });

  final PaymentRegisterEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cashCustomerId = ref.watch(cashCustomerPartyIdProvider).valueOrNull;

    return RegisterEntryCards.payment(
      entry: entry,
      cashCustomerPartyId: cashCustomerId,
      onTap: onTap,
    );
  }
}
