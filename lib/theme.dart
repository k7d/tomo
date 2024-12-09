import 'package:flutter/material.dart';

enum ColorName {
  color1,
  color2,
  color3,
  color4,
  color5,
  color6,
  color7,
  color8,
}

const grayColor = Color(0xFF8a8e9b);
const grayTextColor = Color(0xFFFFFFFF);

extension GetColor on ColorName {
  static const theme = {
    // background, text
    ColorName.color1: [0xFF35a21e, 0xFFFFFFFF],
    ColorName.color2: [0xFF009f81, 0xFFFFFFFF],
    ColorName.color3: [0xFF008ff8, 0xFFFFFFFF],
    ColorName.color4: [0xFFab6cfe, 0xFFFFFFFF],
    ColorName.color5: [0xFFe14adf, 0xFFFFFFFF],
    ColorName.color6: [0xFFff4953, 0xFFFFFFFF],
    ColorName.color7: [0xFFff642d, 0xFFFFFFFF],
    ColorName.color8: [0xFFd87900, 0xFFFFFFFF],
  };
  Color get rgbaColor => Color(GetColor.theme[this]![0]);
  Color get rgbaTextColor => Color(GetColor.theme[this]![1]);
}

const labelTextColor = Color(0xFFc4c7cf);

const labelTextStyle = TextStyle(
  color: labelTextColor,
  fontSize: 14,
  fontWeight: FontWeight.w500,
);

const _bgColor = Color(0xFF6c6e79);

final theme = ThemeData(
  useMaterial3: false,
  colorScheme: const ColorScheme.dark(primary: Color(0xFF82ACFF)),
  scaffoldBackgroundColor: _bgColor,
  textSelectionTheme:
      TextSelectionThemeData(selectionColor: Colors.black.withOpacity(0.8)),
  inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
      floatingLabelStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w500,
      )),
  appBarTheme: const AppBarTheme(
    elevation: 0,
    scrolledUnderElevation: 2,
    backgroundColor: _bgColor,
    foregroundColor: Colors.white,
    titleTextStyle: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w500,
    ),
  ),
  focusColor: Colors.transparent,
);
