import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/color_palette.dart';
import '../../../../shared/widgets/labels/bilingual_label.dart';
import '../../../ledger/domain/entities/party.dart';
import '../providers/payment_providers.dart';

/// Pick a name from hisaab for jama or payment entries.
class RegisterPartyField extends ConsumerWidget {
  const RegisterPartyField({
    super.key,
    required this.selectedParty,
    required this.onPartySelected,
    this.hint = 'Naam chuniye',
  });

  final Party? selectedParty;
  final ValueChanged<Party> onPartySelected;
  final String hint;

  Future<void> _pickParty(BuildContext context, WidgetRef ref) async {
    final party = await showModalBottomSheet<Party>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _RegisterPartyPickerSheet(),
    );
    if (party != null) onPartySelected(party);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _pickParty(context, ref),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const BilingualLabel(
                      english: 'Party',
                      hindi: 'Party chuniye',
                      compact: true,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      selectedParty?.name ?? hint,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: selectedParty == null
                            ? const Color(0xFF8E8E93)
                            : const Color(0xFF1C1C1E),
                      ),
                    ),
                    if (selectedParty?.phone.isNotEmpty ?? false) ...[
                      const SizedBox(height: 4),
                      Text(
                        selectedParty!.phone,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF636366),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: ColorPalette.purple),
            ],
          ),
        ),
      ),
    );
  }
}

class _RegisterPartyPickerSheet extends ConsumerStatefulWidget {
  const _RegisterPartyPickerSheet();

  @override
  ConsumerState<_RegisterPartyPickerSheet> createState() =>
      _RegisterPartyPickerSheetState();
}

class _RegisterPartyPickerSheetState
    extends ConsumerState<_RegisterPartyPickerSheet> {
  final _queryController = TextEditingController();

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _queryController.text;
    final partiesAsync = ref.watch(registerPartySearchProvider(query));

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      builder: (context, scrollController) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const BilingualLabel(
                english: 'Select Party',
                hindi: 'Hisaab se party chuniye',
                compact: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _queryController,
                autofocus: true,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: 'Naam ya mobile…',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: partiesAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Text(error.toString()),
                  data: (parties) {
                    if (parties.isEmpty) {
                      return const Center(
                        child: BilingualLabel(
                          english: 'No names found',
                          hindi: 'Pehle Hisaab mein naam jodein',
                          compact: true,
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: scrollController,
                      itemCount: parties.length,
                      itemBuilder: (context, index) {
                        final party = parties[index];
                        return ListTile(
                          title: Text(party.name),
                          subtitle: party.phone.isEmpty ? null : Text(party.phone),
                          onTap: () => Navigator.pop(context, party),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
