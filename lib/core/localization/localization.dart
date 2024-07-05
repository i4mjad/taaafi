import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'localization.g.dart';

class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  // Static member to have a simple access to the delegate from the MaterialApp
  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  late Map<String, String> _localizedStrings;
  late Map<String, String> _fallbackLocalizedStrings;

  Future<bool> load() async {
    // Load the language JSON file from the "lang" folder
    String jsonString =
        await rootBundle.loadString('asset/i18n/${locale.languageCode}.json');
    Map<String, dynamic> jsonMap = json.decode(jsonString);

    _localizedStrings = jsonMap.map((key, value) {
      return MapEntry(key, value.toString());
    });

    // Load the fallback language JSON file (e.g., English)
    String fallbackJsonString =
        await rootBundle.loadString('asset/i18n/en.json');
    Map<String, dynamic> fallbackJsonMap = json.decode(fallbackJsonString);

    _fallbackLocalizedStrings = fallbackJsonMap.map((key, value) {
      return MapEntry(key, value.toString());
    });

    return true;
  }

  // Helper method to keep the code in the widgets concise
  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(
            Locale('en')); // Fallback to a default locale, e.g., English
  }

  // This method will be called from every widget which needs a localized text
  String translate(String key) {
    return _localizedStrings[key] ??
        _fallbackLocalizedStrings[key] ??
        "Unknown key: $key";
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    // Include all of your supported language codes here
    return ['en', 'ar'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    // AppLocalizations class is where the JSON loading actually runs
    AppLocalizations localizations = AppLocalizations(locale);
    await localizations.load();
    return localizations;
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

@riverpod
class LocaleNotifier extends _$LocaleNotifier {
  @override
  Locale? build() {
    _loadLocale();
    return null;
  }

  void setLocale(Locale locale) {
    state = locale;
    _saveLocale(locale);
  }

  Future<void> toggleLocale() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var languageCode = prefs.getString("languageCode");
    var updatedLocale = languageCode == 'ar' ? Locale('en') : Locale('ar');
    state = updatedLocale;
    _saveLocale(updatedLocale);
  }

  Future<void> _loadLocale() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var languageCode = prefs.getString("languageCode");
    state = Locale(languageCode ?? 'ar', '');
  }

  Future<void> _saveLocale(Locale locale) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString("languageCode", locale.languageCode);
  }
}
