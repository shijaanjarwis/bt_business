import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/utils/validators.dart';

/// Rate input for sale/purchase line items — empty default, numeric keyboard.
class EntryRateField extends StatelessWidget {
  const EntryRateField({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      ],
      decoration: const InputDecoration(
        labelText: 'Rate · Daam',
        hintText: 'Enter Rate',
        isDense: true,
        filled: true,
        fillColor: Colors.white,
      ),
      validator: Validators.entryRate,
      onChanged: (_) => onChanged(),
    );
  }
}
