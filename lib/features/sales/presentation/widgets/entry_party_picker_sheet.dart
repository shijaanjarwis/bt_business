import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/data_revision.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/buttons/app_primary_button.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';
import '../../../../shared/widgets/labels/bilingual_label.dart';
import '../../../ledger/domain/entities/opening_balance_direction.dart';
import '../../../ledger/domain/entities/party.dart';
import '../../../ledger/domain/entities/party_type.dart';
import '../../../ledger/domain/repositories/party_repository.dart';
import '../../../ledger/presentation/providers/party_providers.dart';
import '../providers/sale_providers.dart';

/// Pick a party or add a new one inline while recording.
class EntryPartyPickerSheet extends ConsumerStatefulWidget {
  const EntryPartyPickerSheet({super.key});

  @override
  ConsumerState<EntryPartyPickerSheet> createState() =>
      _EntryPartyPickerSheetState();
}

class _EntryPartyPickerSheetState extends ConsumerState<EntryPartyPickerSheet> {
  final _queryController = TextEditingController();

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _createNewParty() async {
    final name = _queryController.text.trim();
    if (name.isEmpty) return;

    final party = await showModalBottomSheet<Party>(
      context: context,
      isScrollControlled: true,
      builder: (context) => QuickPartyCreateSheet(initialName: name),
    );

    if (party != null && mounted) {
      Navigator.pop(context, party);
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = _queryController.text;
    final partiesAsync = ref.watch(salePartySearchProvider(query));
    final trimmed = query.trim();

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
                hindi: 'Party chuniye ya naya jodein',
                compact: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _queryController,
                autofocus: true,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: 'Naam ya mobile type karein…',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
              if (trimmed.isNotEmpty) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _createNewParty,
                  icon: const Icon(Icons.person_add_rounded, color: ColorPalette.purple),
                  label: Text('Add "$trimmed" · Naya party'),
                ),
              ],
              const SizedBox(height: 12),
              Expanded(
                child: partiesAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Text(error.toString()),
                  data: (parties) {
                    if (parties.isEmpty && trimmed.isEmpty) {
                      return const Center(
                        child: BilingualLabel(
                          english: 'No parties yet',
                          hindi: 'Upar type karke pehla party jodein',
                          compact: true,
                        ),
                      );
                    }
                    if (parties.isEmpty) {
                      return const Center(
                        child: BilingualLabel(
                          english: 'No match — tap Add above',
                          hindi: 'Match nahi mila — upar Add dabayein',
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

/// Minimal party creation from an entry screen.
class QuickPartyCreateSheet extends ConsumerStatefulWidget {
  const QuickPartyCreateSheet({
    super.key,
    required this.initialName,
  });

  final String initialName;

  @override
  ConsumerState<QuickPartyCreateSheet> createState() => _QuickPartyCreateSheetState();
}

class _QuickPartyCreateSheetState extends ConsumerState<QuickPartyCreateSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(text: widget.initialName);
  late final _phoneController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final result = await ref.read(savePartyUseCaseProvider)(
        SavePartyInput(
          name: _nameController.text,
          type: PartyType.both,
          phone: _phoneController.text,
          address: '',
          openingAmount: 0,
          openingDirection: OpeningBalanceDirection.receivable,
          isActive: true,
        ),
      );

      if (result.isFailure) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result.failureOrNull!.message)),
          );
        }
        return;
      }

      notifyDataChanged(ref);
      if (mounted) Navigator.pop(context, result.valueOrNull);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              const BilingualLabel(
                english: 'New Party',
                hindi: 'Naya party jodein',
                compact: true,
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _nameController,
                label: 'Party · Naam',
                validator: (v) => Validators.requiredText(v, fieldName: 'Naam'),
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _phoneController,
                label: 'Mobile (optional) · Mobile',
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return null;
                  return Validators.indianPhone(value);
                },
              ),
              const SizedBox(height: 20),
              AppPrimaryButton(
                label: 'Save · Save karein',
                isLoading: _isSaving,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
