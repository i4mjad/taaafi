import 'package:flutter/material.dart';
import 'package:reboot_app_3/core/theming/font_weights.dart';

class TextStyles {
  const TextStyles();

  TextStyle get screenHeadding => const TextStyle(
        fontSize: 28,
        decoration: TextDecoration.none,
        fontFamily: 'ExpoArabic',
        fontStyle: FontStyle.normal,
        fontWeight: FontWeightHelper.bold,
        height: 1,
        letterSpacing: 0,
      );

  TextStyle get h1 => const TextStyle(
        fontSize: 40,
        decoration: TextDecoration.none,
        fontFamily: 'ExpoArabic',
        fontStyle: FontStyle.normal,
        fontWeight: FontWeightHelper.semiBold,
        height: 1,
        letterSpacing: 0,
      );

  TextStyle get h2 => const TextStyle(
        fontSize: 30,
        decoration: TextDecoration.none,
        fontFamily: 'ExpoArabic',
        fontStyle: FontStyle.normal,
        fontWeight: FontWeightHelper.semiBold,
        height: 1,
        letterSpacing: 0,
      );

  TextStyle get h3 => const TextStyle(
        fontSize: 28,
        decoration: TextDecoration.none,
        fontFamily: 'ExpoArabic',
        fontStyle: FontStyle.normal,
        fontWeight: FontWeightHelper.semiBold,
        height: 1,
        letterSpacing: 0,
      );

  TextStyle get h4 => const TextStyle(
        fontSize: 24,
        decoration: TextDecoration.none,
        fontFamily: 'ExpoArabic',
        fontStyle: FontStyle.normal,
        fontWeight: FontWeightHelper.semiBold,
        height: 1,
        letterSpacing: 0,
      );

  TextStyle get h5 => const TextStyle(
        fontSize: 21,
        decoration: TextDecoration.none,
        fontFamily: 'ExpoArabic',
        fontStyle: FontStyle.normal,
        fontWeight: FontWeightHelper.semiBold,
        height: 1,
        letterSpacing: 0,
      );

  TextStyle get h6 => const TextStyle(
        fontSize: 16,
        decoration: TextDecoration.none,
        fontFamily: 'ExpoArabic',
        fontStyle: FontStyle.normal,
        fontWeight: FontWeightHelper.semiBold,
        height: 1,
        letterSpacing: 0,
      );

  TextStyle get bodyLarge => const TextStyle(
        fontSize: 18,
        decoration: TextDecoration.none,
        fontFamily: 'ExpoArabic',
        fontStyle: FontStyle.normal,
        fontWeight: FontWeightHelper.book,
        height: 27 / 18,
        letterSpacing: 0,
      );

  TextStyle get body => const TextStyle(
        fontSize: 16,
        decoration: TextDecoration.none,
        fontFamily: 'ExpoArabic',
        fontStyle: FontStyle.normal,
        fontWeight: FontWeightHelper.book,
        height: 24 / 16,
        letterSpacing: 0,
      );

  TextStyle get footnote => const TextStyle(
        fontSize: 14,
        decoration: TextDecoration.none,
        fontFamily: 'ExpoArabic',
        fontStyle: FontStyle.normal,
        fontWeight: FontWeightHelper.book,
        height: 20 / 14,
        letterSpacing: 0,
      );

  TextStyle get caption => const TextStyle(
        fontSize: 13,
        decoration: TextDecoration.none,
        fontFamily: 'ExpoArabic',
        fontStyle: FontStyle.normal,
        fontWeight: FontWeightHelper.book,
        height: 20 / 13,
        letterSpacing: 0,
      );

  TextStyle get small => const TextStyle(
        fontSize: 12,
        decoration: TextDecoration.none,
        fontFamily: 'ExpoArabic',
        fontStyle: FontStyle.normal,
        fontWeight: FontWeightHelper.book,
        height: 18 / 12,
        letterSpacing: 0,
      );

  TextStyle get footnoteSelected => const TextStyle(
        fontSize: 14,
        decoration: TextDecoration.none,
        fontFamily: 'ExpoArabic',
        fontStyle: FontStyle.normal,
        fontWeight: FontWeightHelper.medium,
        height: 20 / 14,
        letterSpacing: 0,
      );

  TextStyle get smallBold => const TextStyle(
        fontSize: 12,
        decoration: TextDecoration.none,
        fontFamily: 'ExpoArabic',
        fontStyle: FontStyle.normal,
        fontWeight: FontWeightHelper.semiBold,
        height: 18 / 12,
        letterSpacing: 0,
      );

  TextStyle get tinyBold => const TextStyle(
        fontSize: 8,
        decoration: TextDecoration.none,
        fontFamily: 'ExpoArabic',
        fontStyle: FontStyle.normal,
        fontWeight: FontWeightHelper.semiBold,
        height: 18 / 8,
        letterSpacing: 0,
      );

  TextStyle get tiny => const TextStyle(
        fontSize: 8,
        decoration: TextDecoration.none,
        fontFamily: 'ExpoArabic',
        fontStyle: FontStyle.normal,
        fontWeight: FontWeightHelper.medium,
        height: 18 / 8,
        letterSpacing: 0,
      );

  TextStyle get bodyTiny => const TextStyle(
        fontSize: 10,
        decoration: TextDecoration.none,
        fontFamily: 'ExpoArabic',
        fontStyle: FontStyle.normal,
        fontWeight: FontWeightHelper.medium,
        height: 15 / 10,
        letterSpacing: 0,
      );
}

final textStyles = TextStyles();
