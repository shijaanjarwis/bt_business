import 'package:flutter/material.dart';

import '../../../../shared/widgets/inputs/app_search_field.dart';

class PartySearchBar extends StatelessWidget {
  const PartySearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return AppSearchField(
      controller: controller,
      onChanged: onChanged,
      onClear: onClear,
    );
  }
}
