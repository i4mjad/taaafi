import 'package:flutter/material.dart';
import 'package:reboot_app_3/shared/constants/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

CustomTheme currentTheme = CustomTheme();

class CustomTheme extends ChangeNotifier {
  final String key = "theme";
  SharedPreferences _prefs;
  bool _darkTheme = false;

  bool get darkTheme => _darkTheme;

  CustomTheme() {
    _darkTheme = false;
    _loadFromPrefs();
  }

  toggleTheme() {
    _darkTheme = !_darkTheme;
    _saveToPrefs();
    notifyListeners();
  }

  _initPrefs() async {
    if (_prefs == null) _prefs = await SharedPreferences.getInstance();
  }

  _loadFromPrefs() async {
    await _initPrefs();
    _darkTheme = _prefs.getBool(key) ?? true;
    notifyListeners();
  }

  _saveToPrefs() async {
    await _initPrefs();
    _prefs.setBool(key, _darkTheme);
  }
}

ThemeData get lightTheme {
  return ThemeData(
    brightness: Brightness.light,
    primaryColor: lightPrimaryColor,
    secondaryHeaderColor: lightSeconderyTextColor,
    hintColor: lightPrimaryTextColor,
    backgroundColor: lightBackgroundColor,
    cardColor: lightCardColor,
    scaffoldBackgroundColor: seconderyColor,
    canvasColor: lightPrimaryColor,
    bottomAppBarColor: lightCardColor,
    focusColor: lightPrimaryColor,
    appBarTheme: AppBarTheme(
      backgroundColor: seconderyColor,
    ),
    indicatorColor: Colors.blue[900],
  );
}

ThemeData get darkTheme {
  return ThemeData(
    brightness: Brightness.dark,
    primaryColor: Colors.white,
    secondaryHeaderColor: darkSeconderyTextColor,
    backgroundColor: darkBackgroundColor,
    scaffoldBackgroundColor: darkBackgroundColor,
    cardColor: darkCardColor,
    canvasColor: darkCardColor,
    bottomAppBarColor: darkCardColor,
    hintColor: darkPrimaryTextColor,
    focusColor: darkCardColor,
    appBarTheme: AppBarTheme(
      backgroundColor: darkBackgroundColor,
    ),
    indicatorColor: Colors.blue[300],
  );
}
