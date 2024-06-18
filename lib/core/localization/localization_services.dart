import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleService {
  static Future<String?> getSelectedLocale() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString("languageCode");
  }

  static void setLocale(
      BuildContext context, String locale, WidgetRef ref) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('languageCode', locale);
    final selectedLocale = await prefs.getString('languageCode');
    final getSelectedLocale = Locale(selectedLocale ?? '', '');

    ref.watch(localeNotifierProvider.notifier).setLocale(getSelectedLocale);
  }
}
