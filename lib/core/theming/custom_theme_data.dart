import 'package:flutter/material.dart';
import 'package:reboot_app_3/core/theming/dark_theme_colors.dart';
import 'package:reboot_app_3/core/theming/theme_colors.dart';

class CustomThemeData {
  final MaterialColor primary;
  final MaterialColor secondary;
  final MaterialColor tint;
  final MaterialColor success;
  final MaterialColor warn;
  final MaterialColor grey;
  final MaterialColor error;
  final MaterialColor backgroundColor;
  final MaterialColor calenderHeaderBackgound;
  final MaterialColor postInputBackgound;

  const CustomThemeData({
    required this.primary,
    required this.secondary,
    required this.tint,
    required this.success,
    required this.warn,
    required this.grey,
    required this.error,
    required this.backgroundColor,
    required this.calenderHeaderBackgound,
    required this.postInputBackgound,
  });
}

CustomThemeData getLightCustomTheme(int colorThemeIndex) {
  return CustomThemeData(
    primary: getPrimarySwatch(colorThemeIndex),
    backgroundColor: lightBackgroundSwatch,
    secondary: lightSecondarySwatch,
    tint: lightTintSwatch,
    success: lightSuccessSwatch,
    warn: lightWarnSwatch,
    grey: lightGreySwatch,
    error: lightErrorSwatch,
    calenderHeaderBackgound: calenderHeaderBackgoundSwatch,
    postInputBackgound: lightPostInputBackgoundSwatch,
  );
}

const CustomThemeData darkCustomTheme = CustomThemeData(
  primary: darkPrimarySwatch,
  backgroundColor: darkBackgroundSwatch,
  secondary: darkSecondarySwatch,
  tint: darkTintSwatch,
  success: darkSuccessSwatch,
  warn: darkWarnSwatch,
  grey: darkGreySwatch,
  error: darkErrorSwatch,
  calenderHeaderBackgound: darkCalenderHeaderBackgoundSwatch,
  postInputBackgound: darkPostInputBackgoundSwatch,
);
