import 'package:flutter/material.dart';
import 'package:reboot_app_3/shared/constants/constants.dart';

CustomTheme currentTheme = CustomTheme();

class CustomTheme with ChangeNotifier {
  static bool _isDarkTheme = false;
  ThemeMode get currentTheme => _isDarkTheme ? ThemeMode.dark : ThemeMode.light;

  void toggleTheme() {
    _isDarkTheme = !_isDarkTheme;
    notifyListeners();
  }

  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: lightPrimaryColor,
      secondaryHeaderColor: lightSeconderyTextColor,
      hintColor: lightPrimaryTextColor,
      backgroundColor: lightBackgroundColor,
      cardColor: lightCardColor,
      scaffoldBackgroundColor: seconderyColor,
      bottomAppBarColor: lightCardColor,
      appBarTheme: AppBarTheme(
        backgroundColor: seconderyColor,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      primaryColor: Colors.white,
      secondaryHeaderColor: darkSeconderyTextColor,
      backgroundColor: darkBackgroundColor,
      scaffoldBackgroundColor: darkBackgroundColor,
      bottomAppBarColor: darkCardColor,
      hintColor: darkPrimaryTextColor,
      appBarTheme: AppBarTheme(
        backgroundColor: darkBackgroundColor,
      ),
    );
  }
}
