import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/data_revision.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/branding/developer_footer.dart';
import '../../../../shared/widgets/buttons/app_primary_button.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';
import '../../../../shared/widgets/labels/bilingual_label.dart';
import '../../../../shared/widgets/layout/main_shell_insets.dart';
import '../../../../shared/widgets/layout/responsive_form_container.dart';
import '../../../../shared/widgets/scaffold/app_register_app_bar.dart';
import '../../domain/repositories/expense_repository.dart';
import '../providers/payment_providers.dart';

/// Kharch entry — simple name and amount.
class ExpenseFormPage extends ConsumerStatefulWidget {
  const ExpenseFormPage({super.key});

  @override
  ConsumerState<ExpenseFormPage> createState() => _ExpenseFormPageState();
}

class _ExpenseFormPageState extends ConsumerState<ExpenseFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  DateTime _date = DateTime.now();
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final amount =
        double.tryParse(_amountController.text.replaceAll(',', '').trim()) ?? 0;

    setState(() => _isSaving = true);
    try {
      final result = await ref.read(recordExpenseUseCaseProvider)(
        RecordExpenseInput(
          name: _nameController.text.trim(),
          amount: amount,
          date: _date,
          note: _noteController.text.trim().isEmpty ? null : _noteController.text,
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
      if (mounted) context.pop();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorPalette.background,
      appBar: const AppRegisterAppBar(
        english: 'Expense',
        hindi: 'Kharcha likho',
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsets.fromLTRB(20, 0, 20, MainShellInsets.scrollBottom(context)),
            children: [
              ResponsiveFormContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppTextField(
                      english: 'Expense Name',
                      hindi: 'Naam',
                      controller: _nameController,
                      validator: (value) =>
                          Validators.requiredText(value, fieldName: 'Naam'),
                    ),
                    const SizedBox(height: 16),
                    Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: _pickDate,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const BilingualLabel(
                                      english: 'Date',
                                      hindi: 'Kab hua',
                                      compact: true,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      DateFormatter.shortDate(_date),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.calendar_today_rounded,
                                color: ColorPalette.purple,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      english: 'Amount',
                      hindi: 'Kitna',
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: Validators.positiveAmount,
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      english: 'Note',
                      hindi: 'Yaad',
                      controller: _noteController,
                      helper: 'Optional',
                      maxLines: 2,
                    ),
                    const SizedBox(height: 28),
                    AppPrimaryButton(
                      english: 'Save',
                      hindi: 'Save Karein',
                      isLoading: _isSaving,
                      onPressed: _save,
                    ),
                  ],
                ),
              ),
              const DeveloperFooter(),
            ],
          ),
        ),
      ),
    );
  }
}
