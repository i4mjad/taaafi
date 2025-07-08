// Translations registry – edit language files, not this map.
// The actual key→string maps live in separate files for maintainability.

import 'en_translations.dart';
import 'ar_translations.dart';

/// Master translation lookup used by AppLocalizations.
/// Add new languages by creating a `xx_translations.dart` and
/// registering it here.
const Map<String, Map<String, String>> translations = {
  'en': kEn,
  'ar': kAr,
};
