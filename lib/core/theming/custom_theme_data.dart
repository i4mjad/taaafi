import 'package:flutter/material.dart';
import 'package:reboot_app_3/core/theming/theme_colors.dart';

class CustomThemeData {
  final MaterialColor primary;
  final MaterialColor secondary;
  final MaterialColor tint;
  final MaterialColor success;
  final MaterialColor warn;
  final MaterialColor grey;
  final MaterialColor error;

  const CustomThemeData({
    required this.primary,
    required this.secondary,
    required this.tint,
    required this.success,
    required this.warn,
    required this.grey,
    required this.error,
  });
}

const CustomThemeData lightCustomTheme = CustomThemeData(
  primary: MaterialColor(
    0xff376d71,
    <int, Color>{
      50: ThemeColors.primary50,
      100: ThemeColors.primary100,
      200: ThemeColors.primary200,
      300: ThemeColors.primary300,
      400: ThemeColors.primary400,
      500: ThemeColors.primary500,
      600: ThemeColors.primary600,
      700: ThemeColors.primary700,
      800: ThemeColors.primary800,
      900: ThemeColors.primary900,
    },
  ),
  secondary: MaterialColor(
    0xff94c5c9,
    <int, Color>{
      50: ThemeColors.secondary50,
      100: ThemeColors.secondary100,
      200: ThemeColors.secondary200,
      300: ThemeColors.secondary300,
      400: ThemeColors.secondary400,
      500: ThemeColors.secondary500,
      600: ThemeColors.secondary600,
      700: ThemeColors.secondary700,
      800: ThemeColors.secondary800,
      900: ThemeColors.secondary900,
    },
  ),
  tint: MaterialColor(
    0xffefc0aa,
    <int, Color>{
      50: ThemeColors.tint50,
      100: ThemeColors.tint100,
      200: ThemeColors.tint200,
      300: ThemeColors.tint300,
      400: ThemeColors.tint400,
      500: ThemeColors.tint500,
      600: ThemeColors.tint600,
      700: ThemeColors.tint700,
      800: ThemeColors.tint800,
      900: ThemeColors.tint900,
    },
  ),
  success: MaterialColor(
    0xff38c172,
    <int, Color>{
      50: ThemeColors.sucess50,
      100: ThemeColors.sucess100,
      200: ThemeColors.sucess200,
      300: ThemeColors.sucess300,
      400: ThemeColors.sucess400,
      500: ThemeColors.sucess500,
      600: ThemeColors.sucess600,
      700: ThemeColors.sucess700,
      800: ThemeColors.sucess800,
      900: ThemeColors.sucess900,
    },
  ),
  warn: MaterialColor(
    0xfff1c863,
    <int, Color>{
      50: ThemeColors.warn50,
      100: ThemeColors.warn100,
      200: ThemeColors.warn200,
      300: ThemeColors.warn300,
      400: ThemeColors.warn400,
      500: ThemeColors.warn500,
      600: ThemeColors.warn600,
      700: ThemeColors.warn700,
      800: ThemeColors.warn800,
      900: ThemeColors.warn900,
    },
  ),
  grey: MaterialColor(
    0xff95a1ac,
    <int, Color>{
      50: ThemeColors.grey50,
      100: ThemeColors.grey100,
      200: ThemeColors.grey200,
      300: ThemeColors.grey300,
      400: ThemeColors.grey400,
      500: ThemeColors.grey500,
      600: ThemeColors.grey600,
      700: ThemeColors.grey700,
      800: ThemeColors.grey800,
      900: ThemeColors.grey900,
    },
  ),
  error: MaterialColor(
    0xffdf1111,
    <int, Color>{
      50: ThemeColors.error50,
      100: ThemeColors.error100,
      200: ThemeColors.error200,
      300: ThemeColors.error300,
      400: ThemeColors.error400,
      500: ThemeColors.error500,
      600: ThemeColors.error600,
      700: ThemeColors.error700,
      800: ThemeColors.error800,
      900: ThemeColors.error900,
    },
  ),
);

// TODO: this is now using the same color scheme for the light mood, do check the best way to add a custome color scheme for it
const CustomThemeData darkCustomTheme = CustomThemeData(
  primary: MaterialColor(
    0xff274d50,
    <int, Color>{
      50: ThemeColors.primary50,
      100: ThemeColors.primary100,
      200: ThemeColors.primary200,
      300: ThemeColors.primary300,
      400: ThemeColors.primary400,
      500: ThemeColors.primary500,
      600: ThemeColors.primary600,
      700: ThemeColors.primary700,
      800: ThemeColors.primary800,
      900: ThemeColors.primary900,
    },
  ),
  secondary: MaterialColor(
    0xff3e5354,
    <int, Color>{
      50: ThemeColors.secondary50,
      100: ThemeColors.secondary100,
      200: ThemeColors.secondary200,
      300: ThemeColors.secondary300,
      400: ThemeColors.secondary400,
      500: ThemeColors.secondary500,
      600: ThemeColors.secondary600,
      700: ThemeColors.secondary700,
      800: ThemeColors.secondary800,
      900: ThemeColors.secondary900,
    },
  ),
  tint: MaterialColor(
    0xff645147,
    <int, Color>{
      50: ThemeColors.tint50,
      100: ThemeColors.tint100,
      200: ThemeColors.tint200,
      300: ThemeColors.tint300,
      400: ThemeColors.tint400,
      500: ThemeColors.tint500,
      600: ThemeColors.tint600,
      700: ThemeColors.tint700,
      800: ThemeColors.tint800,
      900: ThemeColors.tint900,
    },
  ),
  success: MaterialColor(
    0xff185130,
    <int, Color>{
      50: ThemeColors.sucess50,
      100: ThemeColors.sucess100,
      200: ThemeColors.sucess200,
      300: ThemeColors.sucess300,
      400: ThemeColors.sucess400,
      500: ThemeColors.sucess500,
      600: ThemeColors.sucess600,
      700: ThemeColors.sucess700,
      800: ThemeColors.sucess800,
      900: ThemeColors.sucess900,
    },
  ),
  warn: MaterialColor(
    0xff65542a,
    <int, Color>{
      50: ThemeColors.warn50,
      100: ThemeColors.warn100,
      200: ThemeColors.warn200,
      300: ThemeColors.warn300,
      400: ThemeColors.warn400,
      500: ThemeColors.warn500,
      600: ThemeColors.warn600,
      700: ThemeColors.warn700,
      800: ThemeColors.warn800,
      900: ThemeColors.warn900,
    },
  ),
  grey: MaterialColor(
    0xff3f4448,
    <int, Color>{
      50: ThemeColors.grey50,
      100: ThemeColors.grey100,
      200: ThemeColors.grey200,
      300: ThemeColors.grey300,
      400: ThemeColors.grey400,
      500: ThemeColors.grey500,
      600: ThemeColors.grey600,
      700: ThemeColors.grey700,
      800: ThemeColors.grey800,
      900: ThemeColors.grey900,
    },
  ),
  error: MaterialColor(
    0xff5e0707,
    <int, Color>{
      50: ThemeColors.error50,
      100: ThemeColors.error100,
      200: ThemeColors.error200,
      300: ThemeColors.error300,
      400: ThemeColors.error400,
      500: ThemeColors.error500,
      600: ThemeColors.error600,
      700: ThemeColors.error700,
      800: ThemeColors.error800,
      900: ThemeColors.error900,
    },
  ),
);
