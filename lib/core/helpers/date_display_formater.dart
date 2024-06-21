import 'package:intl/intl.dart';

String getDisplayDateTime(DateTime date, String language) {
  String formattedDate =
      DateFormat('d - MMMM - yyyy hh:mm a', language).format(date);
  if (language == 'ar') {
    formattedDate = replaceEasternArabicNumerals(formattedDate);
  }
  return formattedDate;
}

String getDisplayDate(DateTime date, String language) {
  String formattedDate = DateFormat('d - MMMM - yyyy', language).format(date);
  if (language == 'ar') {
    formattedDate = replaceEasternArabicNumerals(formattedDate);
  }
  return formattedDate;
}

String replaceEasternArabicNumerals(String input) {
  const easternArabicNumerals = '٠١٢٣٤٥٦٧٨٩';
  const westernArabicNumerals = '0123456789';
  for (int i = 0; i < easternArabicNumerals.length; i++) {
    input =
        input.replaceAll(easternArabicNumerals[i], westernArabicNumerals[i]);
  }
  return input;
}
