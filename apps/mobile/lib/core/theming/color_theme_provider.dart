import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ColorThemeNotifier extends StateNotifier<int> {
  ColorThemeNotifier() : super(0) {
    _loadSelectedTheme();
  }

  static const String _key = "selected_color_theme";

  Future<void> _loadSelectedTheme() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getInt(_key) ?? 0; // Default to first theme (0)
  }

  Future<void> setColorTheme(int themeIndex) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, themeIndex);
    state = themeIndex;
  }
}

final colorThemeProvider =
    StateNotifierProvider<ColorThemeNotifier, int>((ref) {
  return ColorThemeNotifier();
});
