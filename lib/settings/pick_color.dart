import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:tomo/theme.dart';
import 'package:tomo/inner_shadow.dart';

class _ColorChoice extends StatefulWidget {
  const _ColorChoice({
    required this.color,
    required this.selected,
    required this.onSelected,
    required this.hasFocus,
  });

  final Color color;
  final bool selected;
  final VoidCallback onSelected;
  final bool hasFocus;

  @override
  State<_ColorChoice> createState() => _ColorChoiceState();
}

class _ColorChoiceState extends State<_ColorChoice> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = HSLColor.fromColor(widget.color);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onSelected,
        child: Container(
          width: 39,
          height: 38,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: widget.selected
                  ? widget.hasFocus
                      ? theme.colorScheme.primary
                      : theme.hintColor
                  : Colors.transparent,
              width: 2,
            ),
          ),
          child: InnerShadow(
            shadows: [
              Shadow(
                  color: Colors.white.withOpacity(0.3),
                  offset: const Offset(0, 1),
                  blurRadius: 1),
              Shadow(
                  color: Colors.black.withOpacity(0.5),
                  offset: const Offset(0, -1),
                  blurRadius: 1),
            ],
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomLeft,
                  colors: [
                    color.withLightness(color.lightness * 0.7).toColor(),
                    color.withLightness(color.lightness * 1.1).toColor(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PickColor extends StatefulWidget {
  final ColorName selectedColor;
  final Function(ColorName) onColorSelected;

  const PickColor({
    super.key,
    required this.selectedColor,
    required this.onColorSelected,
  });

  @override
  State<PickColor> createState() => _PickColorState();
}

class _PickColorState extends State<PickColor> {
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  KeyEventResult _handleKeyPress(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      switch (event.logicalKey) {
        case LogicalKeyboardKey.arrowLeft:
          final currentIndex = ColorName.values.indexOf(widget.selectedColor);
          if (currentIndex > 0) {
            final previousColor = ColorName.values[currentIndex - 1];
            widget.onColorSelected(previousColor);
          }
          return KeyEventResult.handled;
        case LogicalKeyboardKey.arrowRight:
          final currentIndex = ColorName.values.indexOf(widget.selectedColor);
          if (currentIndex < ColorName.values.length - 1) {
            final nextColor = ColorName.values[currentIndex + 1];
            widget.onColorSelected(nextColor);
          }
          return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      onKeyEvent: _handleKeyPress,
      child: Builder(builder: (context) {
        final FocusNode focusNode = Focus.of(context);
        final bool hasFocus = focusNode.hasFocus;
        return InputDecorator(
          isFocused: hasFocus,
          decoration: const InputDecoration(labelText: "Color"),
          child: Row(
            children: [
              for (var color in ColorName.values)
                _ColorChoice(
                  color: color.rgbaColor,
                  selected: widget.selectedColor == color,
                  hasFocus: hasFocus,
                  onSelected: () {
                    focusNode.requestFocus();
                    widget.onColorSelected(color);
                  },
                ),
            ],
          ),
        );
      }),
    );
  }
}
