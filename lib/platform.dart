import 'package:flutter/services.dart';

const platform = MethodChannel('dev.k7d.tomo/status_bar');

Function()? onTimerComplete;

void initPlatformCallHandler() {
  platform.setMethodCallHandler((call) async {
    if (call.method == 'onTimerComplete') {
      onTimerComplete?.call();
    }
  });
}

void setStatusBarTimer(
    {required double endTimeMs,
    required double totalDurationSeconds,
    required bool isPaused,
    required double pausedRemainingSeconds,
    required Color bgColor,
    required Color textColor}) {
  platform.invokeMethod('setStatusBarTimer', {
    'endTimeMs': endTimeMs,
    'totalDurationSeconds': totalDurationSeconds,
    'isPaused': isPaused,
    'pausedRemainingSeconds': pausedRemainingSeconds,
    'bgColor': [
      // * 0.8 -> darken color by 20%
      bgColor.red / 255 * 0.8,
      bgColor.green / 255 * 0.8,
      bgColor.blue / 255 * 0.8,
    ],
    'textColor': [
      textColor.red / 255,
      textColor.green / 255,
      textColor.blue / 255,
    ],
  });
}

void clearStatusBarTimer() {
  platform.invokeMethod('clearStatusBarTimer');
}

void openWindow() {
  platform.invokeMethod('openWindow');
}

void closeWindow() {
  platform.invokeMethod('closeWindow');
}

void setContentHeight(double height) {
  platform.invokeMethod('setContentHeight', {'height': height});
}
