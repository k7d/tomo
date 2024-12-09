import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:tomo/app_state.dart';
import 'package:tomo/action_button.dart';
import 'package:tomo/timer_dismiss.dart';
import 'package:tomo/theme.dart';

//// ICON

class TimerIcon extends StatelessWidget {
  const TimerIcon(this.icon, {super.key, this.timer});

  final Icon icon;
  final StartedTimer? timer;

  @override
  Widget build(BuildContext context) {
    return Expanded(
        child: Align(
            alignment: Alignment.centerLeft,
            child: switch (timer) {
              StartedTimer started => TimerDismissIndicator(
                  timer: started,
                  child: icon,
                ),
              _ => icon,
            }));
  }
}

//// DURATION

String formatDuration(Duration duration) {
  String twoDigits(int n) => n.toString().padLeft(2, '0');
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  final seconds = twoDigits(duration.inSeconds.remainder(60));
  if (hours > 0) {
    return "$hours:${twoDigits(minutes)}:$seconds";
  } else {
    return "$minutes:$seconds";
  }
}

const durationTextStyle = TextStyle(
  fontSize: 35,
  fontWeight: FontWeight.w700,
  letterSpacing: 1,
);

class TimerDuration extends StatelessWidget {
  const TimerDuration({super.key, required this.timer});

  final TimerWithConfig timer;

  @override
  Widget build(BuildContext context) {
    String formatted = switch (timer) {
      StartedTimer started => formatDuration(started.remaining),
      _ => formatDuration(timer.config.duration),
    };
    return Text(formatted, style: durationTextStyle);
  }
}

//// NAME

class TimerName extends StatelessWidget {
  const TimerName({super.key, required this.timer, this.showDuration = true});

  final TimerWithConfig timer;
  final bool showDuration;

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
        style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.75,
            color: timer.config.color.rgbaTextColor),
        child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(timer.config.name),
          if (showDuration)
            Consumer<AppState>(
                builder: (context, state, child) => Text(formatDuration(
                    state.getCurrentDayDuration(timer.config.id))))
        ]));
  }
}

//// BUTTON

class TimerButton extends ActionButton {
  TimerButton({
    super.key,
    super.left,
    Widget? center,
    super.right,
    super.padding,
    super.backgroundDecoration,
    super.onPressed,
    required this.timer,
  }) : super(
          center: center ?? TimerDuration(timer: timer),
          color: timer.config.color.rgbaColor,
          textColor: timer.config.color.rgbaTextColor,
        );

  final TimerWithConfig timer;
}

//// PROGRESS DECORATOR

class TimerProgressDecoration extends Decoration {
  const TimerProgressDecoration(this.timer);

  final StartedTimer timer;

  //4
  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) {
    return _CustomDecorationPainter(timer);
  }
}

class _CustomDecorationPainter extends BoxPainter {
  _CustomDecorationPainter(this.timer);

  final StartedTimer timer;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    if (configuration.size == null) return;
    final size = configuration.size!;
    final Rect bounds =
        offset & Size(size.width * timer.completed, size.height);
    final RRect rrect = RRect.fromRectAndCorners(bounds,
        topLeft: const Radius.circular(actionButtonBorderRadius),
        bottomLeft: const Radius.circular(actionButtonBorderRadius));
    Paint paint = Paint()..color = Colors.black.withOpacity(0.15);
    Path path = Path();
    path.addRRect(rrect);
    canvas.drawPath(path, paint);
  }
}
