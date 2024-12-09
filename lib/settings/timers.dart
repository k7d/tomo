import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:tomo/timer_button.dart';
import 'package:tomo/app_state.dart';
import 'package:tomo/action_button.dart';
import 'package:tomo/settings/edit_timer.dart';

class TimerSettingsButton extends TimerButton {
  TimerSettingsButton({
    super.key,
    required super.timer,
    required super.onPressed,
  }) : super(
          left: const Icon(Icons.edit_rounded, size: 32),
          center: TimerDuration(timer: timer),
          right: TimerName(
            timer: timer,
            showDuration: false,
          ),
        );
}

class EditTimers extends StatelessWidget {
  const EditTimers({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, child) {
        var timers = state.timers;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var timer in timers) ...[
              TimerSettingsButton(
                timer: timer,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          EditTimer(timerConfig: timer.config),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
            ActionButton(
              onPressed: () {
                final timerConfig = state.addNewTimer();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditTimer(timerConfig: timerConfig),
                  ),
                );
              },
              left: const Icon(Icons.add_rounded, size: 32),
              center: const Text("New timer"),
            ),
          ],
        );
      },
    );
  }
}
