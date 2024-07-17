import 'package:flutter/material.dart';
import 'package:reboot_app_3/core/theming/custom_theme_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

CustomTheme currentTheme = CustomTheme();

class CustomTheme extends ChangeNotifier {
  final String key = "theme";
  SharedPreferences? _prefs;
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
    _darkTheme =
        _prefs!.getBool(key) ?? false; // Default to false for light theme
    notifyListeners();
  }

  _saveToPrefs() async {
    await _initPrefs();
    _prefs!.setBool(key, _darkTheme);
  }
}

// Define the custom theme data

class AppTheme extends InheritedWidget {
  final CustomThemeData customThemeData;

  const AppTheme({
    required this.customThemeData,
    required Widget child,
  }) : super(child: child);

  static CustomThemeData of(BuildContext context) {
    final AppTheme? result =
        context.dependOnInheritedWidgetOfExactType<AppTheme>();
    assert(result != null, 'No CustomThemeInherited found in context');
    return result!.customThemeData;
  }

  @override
  bool updateShouldNotify(AppTheme oldWidget) {
    return customThemeData != oldWidget.customThemeData;
  }
}

ThemeData get lightTheme {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primarySwatch: lightCustomTheme.primary,
    secondaryHeaderColor: lightCustomTheme.secondary[500],
    hintColor: lightCustomTheme.primary[500],
    // backgroundColor: lightCustomTheme.grey[50],
    scaffoldBackgroundColor: lightCustomTheme.secondary[50],
    cardColor: lightCustomTheme.grey[100],
    canvasColor: lightCustomTheme.primary[50],
    // bottomAppBarColor: lightCustomTheme.grey[200],
    focusColor: lightCustomTheme.primary[500],
    appBarTheme: AppBarTheme(
      backgroundColor: lightCustomTheme.secondary[500],
    ),
    indicatorColor: lightCustomTheme.primary[900],
  );
}

ThemeData get darkTheme {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primarySwatch: darkCustomTheme.primary,
    secondaryHeaderColor: darkCustomTheme.secondary[500],
    hintColor: darkCustomTheme.primary[500],
    // backgroundColor: darkCustomTheme.grey[900],

    scaffoldBackgroundColor: darkCustomTheme.grey[800],
    cardColor: darkCustomTheme.grey[700],
    canvasColor: darkCustomTheme.primary[900],
    focusColor: darkCustomTheme.primary[500],
    bottomAppBarTheme: BottomAppBarTheme(color: darkCustomTheme.grey[600]),
    appBarTheme: AppBarTheme(
      backgroundColor: darkCustomTheme.backgroundColor,
    ),
    indicatorColor: darkCustomTheme.primary[300],
  );
}
