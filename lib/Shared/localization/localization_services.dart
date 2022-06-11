import 'dart:core';
import 'package:flutter/cupertino.dart';
import 'package:reboot_app_3/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleService {
  static Future<String> getSelectedLocale() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return await prefs.getString("languageCode");
  }

  static void setLocale(BuildContext context, String locale) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('languageCode', locale);
    final selectedLocale = await prefs.getString('languageCode');
    final getSelectedLocale = Locale(selectedLocale, '');
    MyApp.setLocale(context, getSelectedLocale);
  }
}
