import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:tomo/app_state.dart';
import 'package:tomo/platform.dart' as platform;
import 'package:tomo/content_root.dart';
import 'package:tomo/timer_button.dart';
import 'package:tomo/timer_dismiss.dart';
import 'package:tomo/settings/settings.dart';
import 'package:tomo/theme.dart';

List<Widget> _buildActiveTimerButtons(AppState state, StartedTimer timer) {
  return [
    TimerButton(
      timer: timer,
      left: TimerDismissIndicator(
          timer: timer,
          child: Icon(
            switch (timer.state) {
              TimerState.done => Icons.check_rounded,
              TimerState.running => Icons.pause_rounded,
              _ => Icons.play_arrow_rounded,
            },
            size: 32,
          )),
      right: TimerName(timer: timer),
      backgroundDecoration: TimerProgressDecoration(timer),
      onPressed: () => switch (timer.state) {
        TimerState.running => state.pauseTimer(),
        TimerState.paused => state.resumeTimer(),
        _ => switch (state.getNextTimer(timer)) {
            StartableTimer nextTimer => state.startTimer(nextTimer),
            _ => state.stopTimer(),
          }
      },
    ),
    const SizedBox(height: 20),
    Row(
      children: [
        Expanded(
            child: TimerButton(
          timer: timer,
          center: const Icon(Icons.stop_rounded, size: 32),
          onPressed: () => state.stopTimer(),
        )),
        const SizedBox(width: 20),
        Expanded(
            child: TimerButton(
          timer: timer,
          center: FittedBox(
              fit: BoxFit.fill,
              child: Text(
                "+${timer.config.plusDuration.inMinutes}m",
                style: durationTextStyle,
              )),
          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 15),
          onPressed: () => state.plusTimer(),
        )),
        const SizedBox(width: 20),
        Expanded(
            child: TimerButton(
          timer: timer,
          center: const Icon(Icons.restart_alt_rounded, size: 32),
          onPressed: () => state.restartTimer(),
        )),
      ],
    ),
    if (timer.state == TimerState.done && timer.config.startNextId != null)
      ...switch (state.getNextTimer(timer)) {
        StartableTimer nextTimer => [
            const SizedBox(height: 20),
            const Text("Will start next:"),
            const SizedBox(height: 10),
            TimerButton(
              left: const Icon(Icons.arrow_forward_rounded, size: 32),
              timer: nextTimer,
              right: TimerName(timer: nextTimer),
            ),
          ],
        _ => [],
      },
  ];
}

List<Widget> _buildStartableTimerButtons(
    AppState state, List<TimerWithConfig> timers) {
  return [
    for (var timer in timers) ...[
      TimerButton(
        timer: timer,
        left: const Icon(Icons.play_arrow_rounded, size: 32),
        center: TimerDuration(timer: timer),
        right: TimerName(timer: timer),
        onPressed: () => state.startTimer(timer),
      ),
      if (timer != timers.last) const SizedBox(height: 20),
    ]
  ];
}

class Timers extends StatelessWidget {
  const Timers({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<AppState>(
        builder: (context, state, child) {
          final activeTimer = state.getActiveTimer();
          _updateStatusBarItem(activeTimer);
          return ContentRoot(
            children: activeTimer != null
                ? _buildActiveTimerButtons(state, activeTimer)
                : _buildStartableTimerButtons(state, state.timers),
          );
        },
      ),
      floatingActionButton: NavButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const Settings()),
        ),
        icon: const Icon(Icons.settings),
        tooltip: "Settings",
      ),
      floatingActionButtonLocation: NavButtonLocation.bottomRight,
    );
  }

  void _updateStatusBarItem(StartedTimer? timer) {
    if (timer == null) {
      platform.updateStatusBarItem(
          remainingTimer: "",
          completed: 0,
          bgColor: grayColor,
          textColor: grayTextColor);
    } else {
      platform.updateStatusBarItem(
          remainingTimer: formatDuration(timer.remaining),
          completed: timer.completed,
          bgColor: timer.config.color.rgbaColor,
          textColor: timer.config.color.rgbaTextColor);
    }
  }
}
