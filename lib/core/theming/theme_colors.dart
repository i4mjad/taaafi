import 'package:flutter/material.dart';

class ThemeColors {
  static const Color backgroundcolor = Color(0xfff8f8f8);
  static const Color primary50 = Color(0xffebf0f1);
  static const Color primary100 = Color(0xffc1d2d3);
  static const Color primary200 = Color(0xffa3bcbe);
  static const Color primary300 = Color(0xff799da0);
  static const Color primary400 = Color(0xff5f8a8d);
  static const Color primary500 = Color(0xff376d71);
  static const Color primary600 = Color(0xff326367);
  static const Color primary700 = Color(0xff274d50);
  static const Color primary800 = Color(0xff1e3c3e);
  static const Color primary900 = Color(0xff172e2f);
  static const Color secondary50 = Color(0xfff4f9fa);
  static const Color secondary100 = Color(0xffdeedee);
  static const Color secondary200 = Color(0xffcee4e6);
  static const Color secondary300 = Color(0xffb7d8db);
  static const Color secondary400 = Color(0xffa9d1d4);
  static const Color secondary500 = Color(0xff94c5c9);
  static const Color secondary600 = Color(0xff87b3b7);
  static const Color secondary700 = Color(0xff698c8f);
  static const Color secondary800 = Color(0xff516c6f);
  static const Color secondary900 = Color(0xff3e5354);
  static const Color tint50 = Color(0xfffdf9f7);
  static const Color tint100 = Color(0xfffaebe5);
  static const Color tint200 = Color(0xfff8e2d8);
  static const Color tint300 = Color(0xfff4d5c6);
  static const Color tint400 = Color(0xfff2cdbb);
  static const Color tint500 = Color(0xffefc0aa);
  static const Color tint600 = Color(0xffd9af9b);
  static const Color tint700 = Color(0xffaa8879);
  static const Color tint800 = Color(0xff836a5e);
  static const Color tint900 = Color(0xff645147);
  static const Color sucess50 = Color(0xffebf9f1);
  static const Color sucess100 = Color(0xffc1ecd3);
  static const Color sucess200 = Color(0xffa3e2be);
  static const Color sucess300 = Color(0xff7ad5a1);
  static const Color sucess400 = Color(0xff60cd8e);
  static const Color sucess500 = Color(0xff38c172);
  static const Color sucess600 = Color(0xff33b068);
  static const Color sucess700 = Color(0xff288951);
  static const Color sucess800 = Color(0xff1f6a3f);
  static const Color sucess900 = Color(0xff185130);
  static const Color warn50 = Color(0xfffefaef);
  static const Color warn100 = Color(0xfffbeecf);
  static const Color warn200 = Color(0xfff9e6b7);
  static const Color warn300 = Color(0xfff6da96);
  static const Color warn400 = Color(0xfff4d382);
  static const Color warn500 = Color(0xfff1c863);
  static const Color warn600 = Color(0xffdbb65a);
  static const Color warn700 = Color(0xffab8e46);
  static const Color warn800 = Color(0xff856e36);
  static const Color warn900 = Color(0xff65542a);
  static const Color grey50 = Color(0xfff4f6f7);
  static const Color grey100 = Color(0xffdee2e5);
  static const Color grey200 = Color(0xffced4d9);
  static const Color grey300 = Color(0xffb8c0c7);
  static const Color grey400 = Color(0xffaab4bd);
  static const Color grey500 = Color(0xff95a1ac);
  static const Color grey600 = Color(0xff88939d);
  static const Color grey700 = Color(0xff6a727a);
  static const Color grey800 = Color(0xff52595f);
  static const Color grey900 = Color(0xff3f4448);
  static const Color error50 = Color(0xfffce7e7);
  static const Color error100 = Color(0xfff5b5b5);
  static const Color error200 = Color(0xfff09292);
  static const Color error300 = Color(0xffea6060);
  static const Color error400 = Color(0xffe54141);
  static const Color error500 = Color(0xffdf1111);
  static const Color error600 = Color(0xffcb0f0f);
  static const Color error700 = Color(0xff9e0c0c);
  static const Color error800 = Color(0xff7b0909);
  static const Color error900 = Color(0xff5e0707);
}

const MaterialColor primarySwatch = MaterialColor(
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
);

const MaterialColor secondarySwatch = MaterialColor(
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
);

const MaterialColor tintSwatch = MaterialColor(
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
);

const MaterialColor successSwatch = MaterialColor(
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
);

const MaterialColor warnSwatch = MaterialColor(
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
);

const MaterialColor greySwatch = MaterialColor(
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
);

const MaterialColor errorSwatch = MaterialColor(
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
);
