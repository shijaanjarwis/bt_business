import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/data_revision.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/buttons/app_primary_button.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';
import '../../../../shared/widgets/labels/bilingual_label.dart';
import '../../../../shared/widgets/sheets/app_bottom_sheet.dart';
import '../../../ledger/domain/entities/opening_balance_direction.dart';
import '../../../ledger/domain/entities/party_type.dart';
import '../../../ledger/domain/repositories/party_repository.dart';
import '../../../ledger/presentation/providers/party_providers.dart';

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
    return Form(
      key: _formKey,
      child: AppBottomSheetLayout(
        showHandle: false,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const BilingualLabel(
              english: 'New Party',
              hindi: 'Naya party jodein',
              compact: true,
            ),
            const SizedBox(height: 16),
            AppTextField(
              english: 'Party',
              hindi: 'Naam',
              controller: _nameController,
              validator: (v) => Validators.requiredText(v, fieldName: 'Naam'),
            ),
            const SizedBox(height: 12),
            AppTextField(
              english: 'Mobile',
              hindi: 'Mobile',
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              helper: 'Optional',
              validator: (value) {
                if (value == null || value.trim().isEmpty) return null;
                return Validators.indianPhone(value);
              },
            ),
          ],
        ),
        footer: AppPrimaryButton(
          english: 'Save',
          hindi: 'Save Karein',
          isLoading: _isSaving,
          onPressed: _save,
        ),
      ),
    );
  }
}
