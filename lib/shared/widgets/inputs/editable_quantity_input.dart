import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/item_unit_library.dart';
import '../../../core/theme/color_palette.dart';

/// Register-style quantity control: minus, editable field, plus.
class EditableQuantityInput extends StatefulWidget {
  const EditableQuantityInput({
    super.key,
    required this.value,
    required this.unit,
    required this.onChanged,
  });

  final double value;
  final String unit;
  final ValueChanged<double> onChanged;

  @override
  State<EditableQuantityInput> createState() => _EditableQuantityInputState();
}

class _EditableQuantityInputState extends State<EditableQuantityInput> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  bool get _allowsDecimal => ItemUnitLibrary.allowsDecimalQuantity(widget.unit);

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: ItemUnitLibrary.formatQuantity(widget.value, widget.unit),
    );
    _focusNode = FocusNode()..addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(covariant EditableQuantityInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_focusNode.hasFocus &&
        (oldWidget.value != widget.value ||
            oldWidget.unit != widget.unit)) {
      _controller.text = ItemUnitLibrary.formatQuantity(widget.value, widget.unit);
    }
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_handleFocusChange)
      ..dispose();
    _controller.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (!_focusNode.hasFocus) {
      _commitQuantity(_controller.text);
    }
  }

  void _commitQuantity(String raw) {
    final next = ItemUnitLibrary.parseQuantity(
      raw,
      unit: widget.unit,
      fallback: widget.value,
    );
    _controller.text = ItemUnitLibrary.formatQuantity(next, widget.unit);
    if (next != widget.value) {
      widget.onChanged(next);
    } else {
      setState(() {});
    }
  }

  void _changeBy(double delta) {
    final next = ItemUnitLibrary.clampQuantity(widget.value + delta, widget.unit);
    _controller.text = ItemUnitLibrary.formatQuantity(next, widget.unit);
    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _QtyButton(icon: Icons.remove_rounded, onTap: () => _changeBy(-1)),
        SizedBox(
          width: 72,
          child: TextFormField(
            controller: _controller,
            focusNode: _focusNode,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.numberWithOptions(decimal: _allowsDecimal),
            inputFormatters: [
              if (_allowsDecimal)
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
              else
                FilteringTextInputFormatter.digitsOnly,
            ],
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 10),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: ColorPalette.purple, width: 1.5),
              ),
            ),
            onChanged: (text) {
              final parsed = double.tryParse(text.trim());
              if (parsed != null && parsed >= 1) {
                widget.onChanged(
                  ItemUnitLibrary.clampQuantity(parsed, widget.unit),
                );
              }
            },
            onEditingComplete: () => _commitQuantity(_controller.text),
            onFieldSubmitted: _commitQuantity,
          ),
        ),
        _QtyButton(icon: Icons.add_rounded, onTap: () => _changeBy(1)),
      ],
    );
  }
}

class _QtyButton extends StatelessWidget {
  const _QtyButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, size: 20, color: ColorPalette.purple),
        ),
      ),
    );
  }
}
