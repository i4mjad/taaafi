import 'package:flutter/material.dart';

class DarkThemeColors {
  static const Color backgroundcolor = Color(0xff121212);

  // Swapped: Secondary colors are now primary
  static const Color primary50 = Color(0xFF0A1F26);
  static const Color primary100 = Color(0xFF133640);
  static const Color primary200 = Color(0xFF1C4D5B);
  static const Color primary300 = Color(0xFF256576);
  static const Color primary400 = Color(0xFF2E7C91);
  static const Color primary500 = Color(0xFF3794AC);
  static const Color primary600 = Color(0xFF4FA9C0);
  static const Color primary700 = Color(0xFF6BB8CD);
  static const Color primary800 = Color(0xFF87C7DA);
  static const Color primary900 = Color(0xFFA3D6E7);

  // Swapped: Primary colors are now secondary
  static const Color secondary50 = Color(0xFF0D1929);
  static const Color secondary100 = Color(0xFF152A4D);
  static const Color secondary200 = Color(0xFF1E3A5F);
  static const Color secondary300 = Color(0xFF2B4C7E);
  static const Color secondary400 = Color(0xFF3D5A8C);
  static const Color secondary500 = Color(0xFF4C6BE6); // Main primary
  static const Color secondary600 = Color(0xFF5E7DEA);
  static const Color secondary700 = Color(0xFF7190EF);
  static const Color secondary800 = Color(0xFF85A2F2);
  static const Color secondary900 = Color(0xFF9BB5F7);

  // Tint - Warm amber/orange tones for dark mode
  static const Color tint50 = Color(0xFF2A1A0F);
  static const Color tint100 = Color(0xFF3D2817);
  static const Color tint200 = Color(0xFF50361F);
  static const Color tint300 = Color(0xFF6B4829);
  static const Color tint400 = Color(0xFF865A33);
  static const Color tint500 = Color(0xFFA16C3D);
  static const Color tint600 = Color(0xFFBB8250);
  static const Color tint700 = Color(0xFFD49863);
  static const Color tint800 = Color(0xFFE0A875);
  static const Color tint900 = Color(0xFFEDB888);

  // Success - Adjusted greens for dark mode
  static const Color sucess50 = Color(0xFF0D2818);
  static const Color sucess100 = Color(0xFF164430);
  static const Color sucess200 = Color(0xFF1F6048);
  static const Color sucess300 = Color(0xFF287C60);
  static const Color sucess400 = Color(0xFF319878);
  static const Color sucess500 = Color(0xFF3AB490);
  static const Color sucess600 = Color(0xFF52C3A1);
  static const Color sucess700 = Color(0xFF6BD1B2);
  static const Color sucess800 = Color(0xFF84DFC3);
  static const Color sucess900 = Color(0xFF9DEDD4);

  // Warning - Adjusted yellows for dark mode
  static const Color warn50 = Color(0xFF2A2310);
  static const Color warn100 = Color(0xFF3F3518);
  static const Color warn200 = Color(0xFF564720);
  static const Color warn300 = Color(0xFF6D5928);
  static const Color warn400 = Color(0xFF846B30);
  static const Color warn500 = Color(0xFF9B7D38);
  static const Color warn600 = Color(0xFFB29040);
  static const Color warn700 = Color(0xFFC9A348);
  static const Color warn800 = Color(0xFFDFB650);
  static const Color warn900 = Color(0xFFF6C958);

  // Grey - Proper scale for dark mode (light text on dark bg)
  static const Color grey50 = Color(0xFF1A1A1A);
  static const Color grey100 = Color(0xFF2D2D2D);
  static const Color grey200 = Color(0xFF404040);
  static const Color grey300 = Color(0xFF525252);
  static const Color grey400 = Color(0xFF6B6B6B);
  static const Color grey500 = Color(0xFF858585);
  static const Color grey600 = Color(0xFF9E9E9E);
  static const Color grey700 = Color(0xFFB8B8B8);
  static const Color grey800 = Color(0xFFD1D1D1);
  static const Color grey900 = Color(0xFFEBEBEB);

  // Error - Adjusted reds for dark mode
  static const Color error50 = Color(0xFF2D0F0F);
  static const Color error100 = Color(0xFF451717);
  static const Color error200 = Color(0xFF5D1F1F);
  static const Color error300 = Color(0xFF752727);
  static const Color error400 = Color(0xFF8D2F2F);
  static const Color error500 = Color(0xFFA53737);
  static const Color error600 = Color(0xFFBD3F3F);
  static const Color error700 = Color(0xFFD54747);
  static const Color error800 = Color(0xFFE55555);
  static const Color error900 = Color(0xFFF06666);

  static const Color darkCalenderHeaderBackgoundColor = Color(0xFF1E1E1E);
  static const Color darkPostInputBackgoundColor = Color(0xFF232323);
}

const MaterialColor darkPrimarySwatch = MaterialColor(
  0xFF3794AC,
  <int, Color>{
    50: DarkThemeColors.primary50,
    100: DarkThemeColors.primary100,
    200: DarkThemeColors.primary200,
    300: DarkThemeColors.primary300,
    400: DarkThemeColors.primary400,
    500: DarkThemeColors.primary500,
    600: DarkThemeColors.primary600,
    700: DarkThemeColors.primary700,
    800: DarkThemeColors.primary800,
    900: DarkThemeColors.primary900,
  },
);

const MaterialColor darkBackgroundSwatch = MaterialColor(
  0xff101010,
  <int, Color>{},
);

const MaterialColor darkCalenderHeaderBackgoundSwatch = MaterialColor(
  0xff101010,
  <int, Color>{},
);

const MaterialColor darkPostInputBackgoundSwatch = MaterialColor(
  0xff232323,
  <int, Color>{},
);

const MaterialColor darkSecondarySwatch = MaterialColor(
  0xFF4C6BE6,
  <int, Color>{
    50: DarkThemeColors.secondary50,
    100: DarkThemeColors.secondary100,
    200: DarkThemeColors.secondary200,
    300: DarkThemeColors.secondary300,
    400: DarkThemeColors.secondary400,
    500: DarkThemeColors.secondary500,
    600: DarkThemeColors.secondary600,
    700: DarkThemeColors.secondary700,
    800: DarkThemeColors.secondary800,
    900: DarkThemeColors.secondary900,
  },
);

const MaterialColor darkTintSwatch = MaterialColor(
  0xFFA16C3D,
  <int, Color>{
    50: DarkThemeColors.tint50,
    100: DarkThemeColors.tint100,
    200: DarkThemeColors.tint200,
    300: DarkThemeColors.tint300,
    400: DarkThemeColors.tint400,
    500: DarkThemeColors.tint500,
    600: DarkThemeColors.tint600,
    700: DarkThemeColors.tint700,
    800: DarkThemeColors.tint800,
    900: DarkThemeColors.tint900,
  },
);

const MaterialColor darkSuccessSwatch = MaterialColor(
  0xFF3AB490,
  <int, Color>{
    50: DarkThemeColors.sucess50,
    100: DarkThemeColors.sucess100,
    200: DarkThemeColors.sucess200,
    300: DarkThemeColors.sucess300,
    400: DarkThemeColors.sucess400,
    500: DarkThemeColors.sucess500,
    600: DarkThemeColors.sucess600,
    700: DarkThemeColors.sucess700,
    800: DarkThemeColors.sucess800,
    900: DarkThemeColors.sucess900,
  },
);

const MaterialColor darkWarnSwatch = MaterialColor(
  0xFF9B7D38,
  <int, Color>{
    50: DarkThemeColors.warn50,
    100: DarkThemeColors.warn100,
    200: DarkThemeColors.warn200,
    300: DarkThemeColors.warn300,
    400: DarkThemeColors.warn400,
    500: DarkThemeColors.warn500,
    600: DarkThemeColors.warn600,
    700: DarkThemeColors.warn700,
    800: DarkThemeColors.warn800,
    900: DarkThemeColors.warn900,
  },
);

const MaterialColor darkGreySwatch = MaterialColor(
  0xff95a1ac,
  <int, Color>{
    50: DarkThemeColors.grey50,
    100: DarkThemeColors.grey100,
    200: DarkThemeColors.grey200,
    300: DarkThemeColors.grey300,
    400: DarkThemeColors.grey400,
    500: DarkThemeColors.grey500,
    600: DarkThemeColors.grey600,
    700: DarkThemeColors.grey700,
    800: DarkThemeColors.grey800,
    900: DarkThemeColors.grey900,
  },
);

const MaterialColor darkErrorSwatch = MaterialColor(
  0xFFA53737,
  <int, Color>{
    50: DarkThemeColors.error50,
    100: DarkThemeColors.error100,
    200: DarkThemeColors.error200,
    300: DarkThemeColors.error300,
    400: DarkThemeColors.error400,
    500: DarkThemeColors.error500,
    600: DarkThemeColors.error600,
    700: DarkThemeColors.error700,
    800: DarkThemeColors.error800,
    900: DarkThemeColors.error900,
  },
);
