import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/ledger/domain/entities/party.dart';
import '../../../features/payments/presentation/providers/payment_providers.dart';
import '../../../features/sales/presentation/providers/sale_providers.dart';
import '../../../features/sales/presentation/widgets/entry_party_picker_sheet.dart';
import '../sheets/app_search_picker_sheet.dart';

enum PartyPickerScope { sale, register }

/// Opens the unified party search picker sheet.
Future<Party?> showPartyPicker(
  BuildContext context,
  WidgetRef ref, {
  PartyPickerScope scope = PartyPickerScope.sale,
  bool allowCreate = true,
}) {
  AsyncValue<List<Party>> watchParties(WidgetRef ref, String query) {
    return switch (scope) {
      PartyPickerScope.sale => ref.watch(salePartySearchProvider(query)),
      PartyPickerScope.register => ref.watch(registerPartySearchProvider(query)),
    };
  }

  return AppSearchPickerSheet.show<Party>(
    context: context,
    englishTitle: 'Party',
    hindiTitle: 'Party Chunein',
    emptyEnglish: 'No party found',
    emptyHindi: 'Koi party nahi mili',
    createLabelEnglish: 'Add new party',
    createLabelHindi: 'Naya party jodein',
    watchItems: watchParties,
    itemBuilder: (context, party, onSelect) {
      return ListTile(
        title: Text(
          party.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: party.phone.isEmpty ? null : Text(party.phone),
        onTap: onSelect,
      );
    },
    onCreate: allowCreate
        ? (name) async {
            if (!context.mounted) return;
            final party = await showModalBottomSheet<Party>(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.white,
              builder: (context) => QuickPartyCreateSheet(initialName: name),
            );
            if (party != null && context.mounted) {
              Navigator.pop(context, party);
            }
          }
        : null,
  );
}
