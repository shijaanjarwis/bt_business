import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ledger/domain/entities/party.dart';
import '../../../../shared/widgets/inputs/app_party_picker_field.dart';
import '../../../../shared/widgets/pickers/show_party_picker.dart';

/// Pick a name from hisaab for jama or payment entries.
class RegisterPartyField extends ConsumerWidget {
  const RegisterPartyField({
    super.key,
    required this.selectedParty,
    required this.onPartySelected,
  });

  final Party? selectedParty;
  final ValueChanged<Party> onPartySelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppPartyPickerField(
      party: selectedParty,
      scope: PartyPickerScope.register,
      allowClear: false,
      onChanged: (party) {
        if (party != null) onPartySelected(party);
      },
    );
  }
}
