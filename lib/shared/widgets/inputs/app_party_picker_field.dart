import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/ledger/domain/entities/party.dart';
import '../inputs/app_picker_field.dart';
import '../pickers/show_party_picker.dart';

/// Bilingual party picker field — opens unified search sheet on tap.
class AppPartyPickerField extends ConsumerWidget {
  const AppPartyPickerField({
    super.key,
    required this.party,
    required this.onChanged,
    this.helper,
    this.scope = PartyPickerScope.sale,
    this.allowClear = true,
  });

  final Party? party;
  final ValueChanged<Party?> onChanged;
  final String? helper;
  final PartyPickerScope scope;
  final bool allowClear;

  Future<void> _pick(BuildContext context, WidgetRef ref) async {
    final selected = await showPartyPicker(
      context,
      ref,
      scope: scope,
    );
    if (selected != null) {
      onChanged(selected);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppPickerField(
      english: 'Party',
      hindi: 'Party',
      helper: helper,
      value: party?.name,
      onTap: () => _pick(context, ref),
      onClear: allowClear && party != null ? () => onChanged(null) : null,
      emptyText: 'Select party',
      emptyHindi: 'Party chunein',
    );
  }
}
