import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../localization/localization.dart';

/// Helper class to handle localization logic for content entities
class LocalizationHelper {
  /// Returns the appropriate name based on the current locale and availability of Arabic translation
  ///
  /// Logic:
  /// - If Arabic locale and nameAr is available: return nameAr
  /// - If Arabic locale and nameAr is null/empty: return name (fallback)
  /// - If other locale: return name
  static String getLocalizedName(
      BuildContext context, String name, String? nameAr) {
    final locale = Localizations.localeOf(context);

    if (locale.languageCode == 'ar') {
      // For Arabic locale, use Arabic name if available, otherwise fallback to primary name
      return (nameAr?.isNotEmpty == true) ? nameAr! : name;
    }

    // For other locales, use primary name
    return name;
  }

  /// Extension method version for easier usage with Riverpod
  static String getLocalizedNameWithRef(
      WidgetRef ref, String name, String? nameAr) {
    final locale = ref.watch(localeNotifierProvider);

    if (locale?.languageCode == 'ar') {
      // For Arabic locale, use Arabic name if available, otherwise fallback to primary name
      return (nameAr?.isNotEmpty == true) ? nameAr! : name;
    }

    // For other locales, use primary name
    return name;
  }
}

/// Extension on String for easier localization
extension LocalizedString on String {
  /// Get localized version of this string with optional Arabic translation
  String localized(BuildContext context, String? arabicTranslation) {
    return LocalizationHelper.getLocalizedName(
        context, this, arabicTranslation);
  }

  /// Get localized version using WidgetRef
  String localizedWithRef(WidgetRef ref, String? arabicTranslation) {
    return LocalizationHelper.getLocalizedNameWithRef(
        ref, this, arabicTranslation);
  }
}
