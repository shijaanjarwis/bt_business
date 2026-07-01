import 'package:flutter/material.dart';

import '../../../../core/theme/color_palette.dart';

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
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: 'Party ya mobile…',
        prefixIcon: const Icon(Icons.search_rounded, color: ColorPalette.purple),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (controller.text.isNotEmpty)
              IconButton(
                onPressed: onClear,
                icon: const Icon(Icons.close_rounded, size: 20),
              ),
            IconButton(
              icon: const Icon(Icons.mic_none_rounded, size: 22),
              onPressed: () {},
              tooltip: 'Awaz se khojo (jald)',
            ),
          ],
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
