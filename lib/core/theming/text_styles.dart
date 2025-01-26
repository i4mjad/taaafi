import 'package:flutter/material.dart';
import 'package:reboot_app_3/core/theming/font_weights.dart';

class TextStyles {
  const TextStyles();

  static TextStyle screenHeadding = const TextStyle(
    fontSize: 28,
    decoration: TextDecoration.none,
    fontFamily: 'Kufam',
    fontStyle: FontStyle.normal,
    fontWeight: FontWeightHelper.bold,
    height: 1,
    letterSpacing: 0,
  );

  static TextStyle h1 = const TextStyle(
    fontSize: 40,
    decoration: TextDecoration.none,
    fontFamily: 'Kufam',
    fontStyle: FontStyle.normal,
    fontWeight: FontWeightHelper.semiBold,
    height: 1,
    letterSpacing: 0,
  );

  static TextStyle h2 = const TextStyle(
    fontSize: 30,
    decoration: TextDecoration.none,
    fontFamily: 'Kufam',
    fontStyle: FontStyle.normal,
    fontWeight: FontWeightHelper.semiBold,
    height: 1,
    letterSpacing: 0,
  );

  static TextStyle h3 = const TextStyle(
    fontSize: 28,
    decoration: TextDecoration.none,
    fontFamily: 'Kufam',
    fontStyle: FontStyle.normal,
    fontWeight: FontWeightHelper.semiBold,
    height: 1,
    letterSpacing: 0,
  );

  static TextStyle h4 = const TextStyle(
    fontSize: 24,
    decoration: TextDecoration.none,
    fontFamily: 'Kufam',
    fontStyle: FontStyle.normal,
    fontWeight: FontWeightHelper.semiBold,
    height: 1,
    letterSpacing: 0,
  );

  static TextStyle h5 = const TextStyle(
    fontSize: 21,
    decoration: TextDecoration.none,
    fontFamily: 'Kufam',
    fontStyle: FontStyle.normal,
    fontWeight: FontWeightHelper.semiBold,
    height: 1,
    letterSpacing: 0,
  );

  static TextStyle h6 = const TextStyle(
    fontSize: 16,
    decoration: TextDecoration.none,
    fontFamily: 'Kufam',
    fontStyle: FontStyle.normal,
    fontWeight: FontWeightHelper.semiBold,
    height: 1,
    letterSpacing: 0,
  );

  static TextStyle bottomNavigationBarLabel = const TextStyle(
    fontSize: 11,
    decoration: TextDecoration.none,
    fontFamily: 'Kufam',
    fontStyle: FontStyle.normal,
    fontWeight: FontWeightHelper.medium,
    height: 20 / 14,
    letterSpacing: 0,
  );

  static TextStyle bodyLarge = const TextStyle(
    fontSize: 18,
    decoration: TextDecoration.none,
    fontFamily: 'ExpoArabic',
    fontStyle: FontStyle.normal,
    fontWeight: FontWeightHelper.book,
    height: 27 / 18,
    letterSpacing: 0,
  );

  static TextStyle body = const TextStyle(
    fontSize: 16,
    decoration: TextDecoration.none,
    fontFamily: 'ExpoArabic',
    fontStyle: FontStyle.normal,
    fontWeight: FontWeightHelper.book,
    height: 24 / 16,
    letterSpacing: 0,
  );

  static TextStyle footnote = const TextStyle(
    fontSize: 14,
    decoration: TextDecoration.none,
    fontFamily: 'ExpoArabic',
    fontStyle: FontStyle.normal,
    fontWeight: FontWeightHelper.book,
    height: 20 / 14,
    letterSpacing: 0,
  );

  static TextStyle caption = const TextStyle(
    fontSize: 13,
    decoration: TextDecoration.none,
    fontFamily: 'ExpoArabic',
    fontStyle: FontStyle.normal,
    fontWeight: FontWeightHelper.book,
    height: 20 / 13,
    letterSpacing: 0,
  );

  static TextStyle small = const TextStyle(
    fontSize: 12,
    decoration: TextDecoration.none,
    fontFamily: 'ExpoArabic',
    fontStyle: FontStyle.normal,
    fontWeight: FontWeightHelper.book,
    height: 18 / 12,
    letterSpacing: 0,
  );

  static TextStyle footnoteSelected = const TextStyle(
    fontSize: 14,
    decoration: TextDecoration.none,
    fontFamily: 'ExpoArabic',
    fontStyle: FontStyle.normal,
    fontWeight: FontWeightHelper.medium,
    height: 20 / 14,
    letterSpacing: 0,
  );

  static TextStyle smallBold = const TextStyle(
    fontSize: 12,
    decoration: TextDecoration.none,
    fontFamily: 'ExpoArabic',
    fontStyle: FontStyle.normal,
    fontWeight: FontWeightHelper.semiBold,
    height: 18 / 12,
    letterSpacing: 0,
  );

  static TextStyle tinyBold = const TextStyle(
    fontSize: 8,
    decoration: TextDecoration.none,
    fontFamily: 'ExpoArabic',
    fontStyle: FontStyle.normal,
    fontWeight: FontWeightHelper.semiBold,
    height: 18 / 8,
    letterSpacing: 0,
  );

  static TextStyle tiny = const TextStyle(
    fontSize: 8,
    decoration: TextDecoration.none,
    fontFamily: 'ExpoArabic',
    fontStyle: FontStyle.normal,
    fontWeight: FontWeightHelper.medium,
    height: 18 / 8,
    letterSpacing: 0,
  );

  static TextStyle bodyTiny = const TextStyle(
    fontSize: 10,
    decoration: TextDecoration.none,
    fontFamily: 'ExpoArabic',
    fontStyle: FontStyle.normal,
    fontWeight: FontWeightHelper.medium,
    height: 15 / 10,
    letterSpacing: 0,
  );
}

class Shadows {
  const Shadows();

  static List<BoxShadow> mainShadows = [
    BoxShadow(
      color: Color.fromRGBO(60, 64, 67, 0.3),
      blurRadius: 2,
      spreadRadius: 0,
      offset: Offset(
        0,
        1,
      ),
    ),
    BoxShadow(
      color: Color.fromRGBO(60, 64, 67, 0.15),
      blurRadius: 6,
      spreadRadius: 2,
      offset: Offset(
        0,
        2,
      ),
    ),
  ];
}
