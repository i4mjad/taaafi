import 'package:flutter/cupertino.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:reboot_app_3/i18n/translations.dart' as tr;

part 'localization.g.dart';

class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  // Static member to have a simple access to the delegate from the MaterialApp
  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// No asynchronous loading required – translations are compile-time constants.
  Future<bool> load() async => true;

  /// Retrieve a localized string for [key] based on the current [locale].
  /// Falls back to English when the key (or language) is missing.
  String translate(String key) {
    return tr.translations[locale.languageCode]?[key] ??
        tr.translations['en']?[key] ??
        'Unknown key: $key';
  }

  // Helper method to keep the code in the widgets concise
  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(
            Locale('en')); // Fallback to a default locale, e.g., English
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
    // No I/O is performed – just instantiate the localizations object.
    return AppLocalizations(locale);
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
