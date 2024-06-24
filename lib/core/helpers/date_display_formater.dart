import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

String getDisplayDateTime(dynamic date, String language) {
  if (date is Timestamp) {
    date = date.toDate();
  }
  String formattedDate =
      DateFormat('d - MMMM - yyyy hh:mm a', language).format(date);
  if (language == 'ar') {
    formattedDate = replaceWesternWithEasternArabicNumerals(formattedDate);
    formattedDate = replaceEnglishAmPmWithArabic(formattedDate);
  }
  return formattedDate;
}

String getDisplayDate(dynamic date, String language) {
  if (date is Timestamp) {
    date = date.toDate();
  }
  String formattedDate = DateFormat('d - MMMM - yyyy', language).format(date);
  if (language == 'ar') {
    formattedDate = replaceWesternWithEasternArabicNumerals(formattedDate);
  }
  return formattedDate;
}

Timestamp parseDisplayDateTime(String dateStr, String language) {
  if (language == 'ar') {
    dateStr = replaceEasternWithWesternArabicNumerals(dateStr);
    dateStr = replaceArabicMonthWithEnglish(dateStr);
    dateStr = replaceArabicAmPmWithEnglish(dateStr);
  }
  DateTime parsedDate =
      DateFormat('d - MMMM - yyyy hh:mm a', 'en').parse(dateStr);
  return Timestamp.fromDate(parsedDate);
}

Timestamp parseDisplayDate(String dateStr, String language) {
  if (language == 'ar') {
    dateStr = replaceEasternWithWesternArabicNumerals(dateStr);
    dateStr = replaceArabicMonthWithEnglish(dateStr);
  }
  DateTime parsedDate = DateFormat('d - MMMM - yyyy', 'en').parse(dateStr);
  return Timestamp.fromDate(parsedDate);
}

String replaceWesternWithEasternArabicNumerals(String input) {
  const westernArabicNumerals = [
    '0',
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9'
  ];
  const easternArabicNumerals = [
    '٠',
    '١',
    '٢',
    '٣',
    '٤',
    '٥',
    '٦',
    '٧',
    '٨',
    '٩'
  ];

  for (int i = 0; i < westernArabicNumerals.length; i++) {
    input =
        input.replaceAll(westernArabicNumerals[i], easternArabicNumerals[i]);
  }

  return input;
}

String replaceEasternWithWesternArabicNumerals(String input) {
  const westernArabicNumerals = [
    '0',
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9'
  ];
  const easternArabicNumerals = [
    '٠',
    '١',
    '٢',
    '٣',
    '٤',
    '٥',
    '٦',
    '٧',
    '٨',
    '٩'
  ];

  for (int i = 0; i < easternArabicNumerals.length; i++) {
    input =
        input.replaceAll(easternArabicNumerals[i], westernArabicNumerals[i]);
  }

  return input;
}

String replaceArabicMonthWithEnglish(String input) {
  const arabicToEnglishMonths = {
    'يناير': 'January',
    'فبراير': 'February',
    'مارس': 'March',
    'أبريل': 'April',
    'مايو': 'May',
    'يونيو': 'June',
    'يوليو': 'July',
    'أغسطس': 'August',
    'سبتمبر': 'September',
    'أكتوبر': 'October',
    'نوفمبر': 'November',
    'ديسمبر': 'December'
  };

  arabicToEnglishMonths.forEach((arabic, english) {
    input = input.replaceAll(arabic, english);
  });

  return input;
}

String replaceArabicAmPmWithEnglish(String input) {
  const arabicToEnglishAmPm = {'ص': 'AM', 'م': 'PM'};

  arabicToEnglishAmPm.forEach((arabic, english) {
    input = input.replaceAll(arabic, english);
  });

  return input;
}

String replaceEnglishAmPmWithArabic(String input) {
  const englishToArabicAmPm = {'AM': 'ص', 'PM': 'م'};

  englishToArabicAmPm.forEach((english, arabic) {
    input = input.replaceAll(english, arabic);
  });

  return input;
}
