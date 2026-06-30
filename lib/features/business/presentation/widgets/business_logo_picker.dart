import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/color_palette.dart';

/// Picks and previews the business logo.
class BusinessLogoPicker extends StatelessWidget {
  const BusinessLogoPicker({
    super.key,
    required this.logoPath,
    required this.onPick,
    required this.onRemove,
  });

  final String? logoPath;
  final ValueChanged<String> onPick;
  final VoidCallback onRemove;

  Future<void> _pickLogo(BuildContext context) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (file == null) return;
    onPick(file.path);
  }

  @override
  Widget build(BuildContext context) {
    final hasLogo = logoPath != null && logoPath!.isNotEmpty;

    return Column(
      children: [
        GestureDetector(
          onTap: () => _pickLogo(context),
          child: Container(
            width: 112,
            height: 112,
            decoration: BoxDecoration(
              color: ColorPalette.purple.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: ColorPalette.purple.withValues(alpha: 0.18),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: hasLogo
                ? Image.file(
                    File(logoPath!),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => _placeholder(),
                  )
                : _placeholder(),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => _pickLogo(context),
          child: Text(hasLogo ? 'Change Logo' : 'Add Logo'),
        ),
        if (hasLogo)
          TextButton(
            onPressed: onRemove,
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFFF3B30)),
            child: const Text('Remove Logo'),
          ),
      ],
    );
  }

  Widget _placeholder() {
    return const Center(
      child: Icon(
        Icons.storefront_rounded,
        size: 40,
        color: ColorPalette.purple,
      ),
    );
  }
}
