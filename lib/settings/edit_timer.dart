import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:tomo/app_state.dart';
import 'package:tomo/content_root.dart';
import 'package:tomo/action_button.dart';
import 'package:tomo/settings/auto_select_text_field.dart';
import 'package:tomo/settings/edit_duration.dart';
import 'package:tomo/settings/pick_color.dart';
import 'package:tomo/settings/pick_sound.dart';
import 'package:tomo/theme.dart';

class EditTimer extends StatelessWidget {
  const EditTimer({super.key, required this.timerConfig});

  final TimerConfig timerConfig;

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, child) {
        final bgColor = HSLColor.fromColor(timerConfig.color.rgbaColor)
            .withLightness(0.15)
            .withSaturation(0.2)
            .withLightness(0.3)
            .toColor();
        return Scaffold(
          body: ContentRoot(
            children: [
              AutoSelectTextField(
                initialValue: timerConfig.name,
                decoration: const InputDecoration(labelText: 'Name'),
                onChanged: (value) {
                  timerConfig.name = value;
                  state.updateTimerConfig(timerConfig);
                },
              ),
              const SizedBox(height: 20),
              EditDuration(
                initialDuration: timerConfig.duration,
                onDurationChanged: (value) {
                  timerConfig.duration = value;
                  state.updateTimerConfig(timerConfig);
                },
              ),
              const SizedBox(height: 20),
              PickColor(
                selectedColor: timerConfig.color,
                onColorSelected: (color) {
                  timerConfig.color = color;
                  state.updateTimerConfig(timerConfig);
                },
              ),
              const SizedBox(height: 20),
              PickSound(
                selectedSound: timerConfig.sound,
                onSoundSelected: (sound) {
                  timerConfig.sound = sound;
                  state.updateTimerConfig(timerConfig);
                },
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField(
                isExpanded: true,
                value: timerConfig.startNextId,
                decoration: const InputDecoration(
                  labelText: 'Start next',
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Nothing'),
                  ),
                  ...state.timerConfigs.map((config) {
                    return DropdownMenuItem<String?>(
                      value: config.id,
                      child: Text(config.name),
                    );
                  }),
                ],
                onChanged: (value) {
                  timerConfig.startNextId = value;
                  state.updateTimerConfig(timerConfig);
                  // Handle start next selection
                },
              ),
              const SizedBox(height: 30),
              ActionButton(
                onPressed: () {
                  state.deleteTimer(timerConfig);
                  Navigator.pop(context);
                },
                left: const Icon(Icons.delete_rounded, size: 32),
                center: const Text('Delete timer'),
              ),
            ],
          ),
          appBar: AppBar(
            title: const Text('Timer settings'),
            backgroundColor: bgColor,
          ),
          backgroundColor: bgColor,
        );
      },
    );
  }
}
