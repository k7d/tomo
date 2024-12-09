import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'package:tomo/app_state.dart';
import 'package:tomo/theme.dart';

class TimerDismissIndicator extends StatefulWidget {
  const TimerDismissIndicator({
    super.key,
    required this.timer,
    required this.child,
  });

  final StartedTimer timer;
  final Widget child;

  @override
  State<TimerDismissIndicator> createState() => _TimerDismissIndicatorState();
}

const _startAngle = -math.pi / 2;

class _TimerDismissIndicatorState extends State<TimerDismissIndicator>
    with TickerProviderStateMixin {
  late AnimationController controller;

  Animation<double>? animation;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: dismissTimerIn,
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _startAnim() {
    controller.forward(from: 0).whenCompleteOrCancel(() {
      animation = null;
    });
    animation = Tween<double>(begin: 0, end: math.pi * 2).animate(controller)
      ..addListener(() {
        setState(() {});
      });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.timer.state == TimerState.done) {
      if (animation == null) {
        _startAnim();
      }
    } else {
      if (animation != null) {
        controller.stop();
        animation = null;
      }
    }
    return switch (animation?.value) {
      double angle => Container(
          // Compensate for 8px padding around child
          transform: Matrix4.translationValues(-4, 0, 0),
          child: CustomPaint(
            painter:
                DismissPainter(angle, widget.timer.config.color.rgbaTextColor),
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: widget.child,
            ),
          ),
        ),
      _ => widget.child,
    };
  }
}

class DismissPainter extends CustomPainter {
  final double angle;
  final Color color;

  DismissPainter(this.angle, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final rect = Rect.fromLTWH(2, 2, size.width - 4, size.height - 4);
    canvas.drawArc(rect, _startAngle, angle, false, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
