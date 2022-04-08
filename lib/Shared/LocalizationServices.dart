import 'dart:core';

import 'package:shared_preferences/shared_preferences.dart';

class LocaleService {

  static Future<String> getSelectedLocale() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return await prefs.getString("languageCode");
  }

}