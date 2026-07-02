import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/color_palette.dart';

/// Unified register search field — debounced for instant-feel typing.
class AppSearchField extends StatefulWidget {
  const AppSearchField({
    super.key,
    required this.controller,
    required this.onChanged,
    this.onClear,
    this.showVoiceButton = true,
    this.autofocus = false,
    this.debounce = AppConstants.searchDebounce,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback? onClear;
  final bool showVoiceButton;
  final bool autofocus;
  final Duration debounce;

  static const String placeholder = 'Search (Khoje)';

  @override
  State<AppSearchField> createState() => _AppSearchFieldState();
}

class _AppSearchFieldState extends State<AppSearchField> {
  Timer? _debounceTimer;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _handleChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(widget.debounce, () {
      if (!mounted) return;
      widget.onChanged(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppDimensions.searchHeight,
      child: TextField(
        controller: widget.controller,
        autofocus: widget.autofocus,
        onChanged: _handleChanged,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: ColorPalette.labelPrimary,
        ),
        decoration: InputDecoration(
          hintText: AppSearchField.placeholder,
          hintStyle: const TextStyle(
            color: ColorPalette.hintText,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: ColorPalette.iconPrimary,
            size: AppDimensions.iconSize,
          ),
          suffixIcon: _SuffixActions(
            controller: widget.controller,
            onClear: widget.onClear,
            showVoiceButton: widget.showVoiceButton,
          ),
          filled: true,
          fillColor: ColorPalette.cardSurface,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimensions.searchRadius),
            borderSide: const BorderSide(color: ColorPalette.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimensions.searchRadius),
            borderSide: const BorderSide(color: ColorPalette.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimensions.searchRadius),
            borderSide: const BorderSide(color: ColorPalette.purple, width: 1.5),
          ),
        ),
      ),
    );
  }
}

class _SuffixActions extends StatelessWidget {
  const _SuffixActions({
    required this.controller,
    required this.onClear,
    required this.showVoiceButton,
  });

  final TextEditingController controller;
  final VoidCallback? onClear;
  final bool showVoiceButton;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final hasText = controller.text.isNotEmpty;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasText && onClear != null)
              IconButton(
                onPressed: onClear,
                icon: const Icon(
                  Icons.close_rounded,
                  size: AppDimensions.iconSizeSm,
                  color: ColorPalette.iconPrimary,
                ),
                tooltip: 'Clear',
              ),
            if (showVoiceButton)
              IconButton(
                onPressed: () {},
                icon: const Icon(
                  Icons.mic_none_rounded,
                  size: AppDimensions.iconSize,
                  color: ColorPalette.iconPrimary,
                ),
                tooltip: 'Voice search (coming soon)',
              ),
          ],
        );
      },
    );
  }
}
