import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:tomo/sound.dart';
import 'package:tomo/svg_icon.dart';

class _SoundChoice extends StatefulWidget {
  const _SoundChoice({
    required this.sound,
    required this.selected,
    required this.onSelected,
    required this.hasFocus,
  });

  final Sound sound;
  final bool selected;
  final VoidCallback onSelected;
  final bool hasFocus;

  @override
  State<_SoundChoice> createState() => _SoundChoiceState();
}

class _SoundChoiceState extends State<_SoundChoice> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onSelected,
        child: Container(
          width: 39,
          height: 38,
          padding: const EdgeInsets.all(6),
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
          child: SvgIcon(widget.sound.name),
        ),
      ),
    );
  }
}

class PickSound extends StatefulWidget {
  final Sound selectedSound;
  final Function(Sound) onSoundSelected;

  const PickSound({
    super.key,
    required this.selectedSound,
    required this.onSoundSelected,
  });

  @override
  State<PickSound> createState() => _PickSoundState();
}

class _PickSoundState extends State<PickSound> {
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
          final currentIndex = Sound.values.indexOf(widget.selectedSound);
          if (currentIndex > 0) {
            final previousSound = Sound.values[currentIndex - 1];
            widget.onSoundSelected(previousSound);
          }
          return KeyEventResult.handled;
        case LogicalKeyboardKey.arrowRight:
          final currentIndex = Sound.values.indexOf(widget.selectedSound);
          if (currentIndex < Sound.values.length - 1) {
            final nextSound = Sound.values[currentIndex + 1];
            widget.onSoundSelected(nextSound);
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
          decoration: const InputDecoration(labelText: "Sound"),
          child: Row(
            children: [
              for (var sound in Sound.values)
                _SoundChoice(
                  sound: sound,
                  selected: widget.selectedSound == sound,
                  hasFocus: hasFocus,
                  onSelected: () {
                    focusNode.requestFocus();
                    widget.onSoundSelected(sound);
                    if (sound != Sound.none) {
                      playSound(sound);
                    }
                  },
                ),
            ],
          ),
        );
      }),
    );
  }
}
