import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class EditDurationPart extends StatefulWidget {
  const EditDurationPart({
    super.key,
    required this.label,
    required this.controller,
    required this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final Function() onChanged;

  @override
  State<EditDurationPart> createState() => _EditDurationPartState();
}

class _EditDurationPartState extends State<EditDurationPart> {
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        widget.controller.selection = TextSelection(
          baseOffset: 0,
          extentOffset: widget.controller.text.length,
        );
      } else {
        if (widget.controller.text.isEmpty) {
          widget.controller.text = "0";
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          TextFormField(
            controller: widget.controller,
            decoration: InputDecoration(labelText: widget.label),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (value) => widget.onChanged(),
            focusNode: _focusNode,
          ),
        ],
      ),
    );
  }
}

class EditDuration extends StatefulWidget {
  const EditDuration({
    super.key,
    required this.initialDuration,
    required this.onDurationChanged,
  });

  final Duration initialDuration;
  final ValueChanged<Duration> onDurationChanged;

  @override
  State<EditDuration> createState() => _EditDurationState();
}

class _EditDurationState extends State<EditDuration> {
  late final TextEditingController _hoursController;
  late final TextEditingController _minutesController;
  late final TextEditingController _secondsController;

  @override
  void initState() {
    super.initState();
    _hoursController = TextEditingController(
        text: (widget.initialDuration.inHours).toString());
    _minutesController = TextEditingController(
        text: (widget.initialDuration.inMinutes % 60).toString());
    _secondsController = TextEditingController(
        text: (widget.initialDuration.inSeconds % 60).toString());
  }

  void _onDurationChanged() {
    final hours = int.tryParse(_hoursController.text) ?? 0;
    final minutes = int.tryParse(_minutesController.text) ?? 0;
    final seconds = int.tryParse(_secondsController.text) ?? 0;
    final duration = Duration(hours: hours, minutes: minutes, seconds: seconds);
    widget.onDurationChanged(duration);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        EditDurationPart(
            label: "Hours",
            controller: _hoursController,
            onChanged: _onDurationChanged),
        const SizedBox(width: 10),
        EditDurationPart(
            label: "Minutes",
            controller: _minutesController,
            onChanged: _onDurationChanged),
        const SizedBox(width: 10),
        EditDurationPart(
            label: "Seconds",
            controller: _secondsController,
            onChanged: _onDurationChanged),
      ],
    );
  }
}
