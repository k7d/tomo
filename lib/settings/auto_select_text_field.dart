import 'package:flutter/material.dart';

class AutoSelectTextField extends StatefulWidget {
  const AutoSelectTextField({
    super.key,
    this.decoration,
    this.initialValue = '',
    this.onChanged,
  });

  final InputDecoration? decoration;
  final String initialValue;
  final Function(String value)? onChanged;

  @override
  State<AutoSelectTextField> createState() => _AutoSelectTextFieldState();
}

class _AutoSelectTextFieldState extends State<AutoSelectTextField> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller.text = widget.initialValue;
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _controller.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _controller.text.length,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      decoration: widget.decoration,
      onChanged: widget.onChanged,
      focusNode: _focusNode,
    );
  }
}
