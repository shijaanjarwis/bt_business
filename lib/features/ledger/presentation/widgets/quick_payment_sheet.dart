import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/data_revision.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/buttons/app_primary_button.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';
import '../../../../shared/widgets/labels/bilingual_label.dart';
import '../../../../shared/widgets/sheets/app_bottom_sheet.dart';
import '../../domain/repositories/party_repository.dart';
import '../providers/party_providers.dart';

enum QuickPaymentMode { received, paid }

/// Record jama or payment from a party hisaab page.
class QuickPaymentSheet extends ConsumerStatefulWidget {
  const QuickPaymentSheet({
    super.key,
    required this.partyId,
    required this.mode,
  });

  final String partyId;
  final QuickPaymentMode mode;

  @override
  ConsumerState<QuickPaymentSheet> createState() => _QuickPaymentSheetState();
}

class _QuickPaymentSheetState extends ConsumerState<QuickPaymentSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final amount =
        double.tryParse(_amountController.text.replaceAll(',', '').trim()) ?? 0;

    setState(() => _isSaving = true);
    try {
      final input = RecordPaymentInput(
        partyId: widget.partyId,
        amount: amount,
        date: DateTime.now(),
      );

      final result = widget.mode == QuickPaymentMode.received
          ? await ref.read(recordPaymentReceivedUseCaseProvider)(input)
          : await ref.read(recordPaymentPaidUseCaseProvider)(input);

      if (result.isFailure) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result.failureOrNull!.message)),
          );
        }
        return;
      }

      notifyDataChanged(ref);
      if (mounted) Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isReceived = widget.mode == QuickPaymentMode.received;

    return Form(
      key: _formKey,
      child: AppBottomSheetLayout(
        showHandle: false,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BilingualLabel(
              english: isReceived ? 'Money Received' : 'Money Paid',
              hindi: isReceived ? 'Jama · Paisa mila' : 'Payment · Paisa diya',
              compact: true,
            ),
            const SizedBox(height: 16),
            AppTextField(
              english: 'Amount',
              hindi: 'Kitna',
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: Validators.positiveAmount,
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
