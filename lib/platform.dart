import 'package:flutter/services.dart';

const platform = MethodChannel('dev.k7d.tomo/status_bar');

void updateStatusBarItem(
    {required String remainingTimer,
    required num completed,
    required Color bgColor,
    required Color textColor}) {
  platform.invokeMethod('updateStatusBarItem', {
    'remainingTime': remainingTimer,
    'completed': completed,
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

void openWindow() {
  platform.invokeMethod('openWindow');
}

void closeWindow() {
  platform.invokeMethod('closeWindow');
}

void setContentHeight(double height) {
  platform.invokeMethod('setContentHeight', {'height': height});
}
