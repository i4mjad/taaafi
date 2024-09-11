import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

String getDisplayDateTime(dynamic date, String language) {
  if (date is Timestamp) {
    date = date.toDate();
  }
  String locale = getLocale(language);
  String formattedDate =
      DateFormat('d - MMMM - yyyy hh:mm a', locale).format(date);
  if (language == 'arabic' || language == 'ar') {
    formattedDate = replaceWesternWithEasternArabicNumerals(formattedDate);
  }
  return formattedDate;
}

String getDisplayDate(dynamic date, String language) {
  if (date is Timestamp) {
    date = date.toDate();
  }

  String locale = getLocale(language);
  String formattedDate = DateFormat('d - MMMM - yyyy', locale).format(date);
  if (language == 'arabic' || language == 'ar') {
    formattedDate = replaceWesternWithEasternArabicNumerals(formattedDate);
  }
  return formattedDate;
}

Timestamp parseDisplayDateTime(String dateStr, String language) {
  if (language == 'arabic' || language == 'ar') {
    dateStr = replaceEasternWithWesternArabicNumerals(dateStr);
    dateStr = replaceArabicMonthWithEnglish(dateStr);
  }
  String locale = getLocale(language);
  DateTime parsedDate =
      DateFormat('d - MMMM - yyyy hh:mm a', locale).parse(dateStr);
  return Timestamp.fromDate(parsedDate);
}

Timestamp parseDisplayDate(String dateStr, String language) {
  if (language == 'arabic' || language == 'ar') {
    dateStr = replaceEasternWithWesternArabicNumerals(dateStr);
    dateStr = replaceArabicMonthWithEnglish(dateStr);
  }
  String locale = getLocale(language);
  DateTime parsedDate = DateFormat('d - MMMM - yyyy', locale).parse(dateStr);
  return Timestamp.fromDate(parsedDate);
}

String getLocale(String language) {
  switch (language) {
    case 'arabic':
      return 'ar';
    case 'english':
      return 'en';
    case 'ar':
      return 'ar';
    default:
      return 'en';
  }
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
        input.replaceAll(easternArabicNumerals[i], westernArabicNumerals[i]);
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

class DisplayDateTime {
  dynamic date;
  late String displayDateTime;

  DisplayDateTime(this.date, String language) {
    displayDateTime = _toDisplay(date, language);
  }

  // Method to convert the date and time to a displayable string
  String _toDisplay(dynamic date, String language) {
    if (date is Timestamp) {
      date = date.toDate();
    }
    String formattedDate =
        DateFormat('d - MMMM - yyyy hh:mm a', language).format(date);
    if (language == 'ar') {
      formattedDate = replaceWesternWithEasternArabicNumerals(formattedDate);
    }
    return formattedDate;
  }

  // Method to parse the displayable string back to a DateTime
  DateTime toDateTime(String language) {
    String dateStr = displayDateTime;
    if (language == 'ar') {
      dateStr = replaceEasternWithWesternArabicNumerals(dateStr);
      dateStr = replaceArabicMonthWithEnglish(dateStr);
    }
    DateTime parsedDate =
        DateFormat('d - MMMM - yyyy hh:mm a', language).parse(dateStr);
    return parsedDate;
  }
}

class DisplayDate {
  dynamic date;
  late String displayDate;

  DisplayDate(this.date, String language) {
    displayDate = _toDisplay(date, language);
  }

  // Method to convert the date to a displayable string
  String _toDisplay(dynamic date, String language) {
    if (date is Timestamp) {
      date = date.toDate();
    }
    String formattedDate = DateFormat('d - MMMM - yyyy', language).format(date);
    if (language == 'ar') {
      formattedDate = replaceWesternWithEasternArabicNumerals(formattedDate);
    }
    return formattedDate;
  }

  // Method to parse the displayable string back to a DateTime
  DateTime toDate(String language) {
    String dateStr = displayDate;
    if (language == 'ar') {
      dateStr = replaceEasternWithWesternArabicNumerals(dateStr);
      dateStr = replaceArabicMonthWithEnglish(dateStr);
    }
    DateTime parsedDate =
        DateFormat('d - MMMM - yyyy', language).parse(dateStr);
    return parsedDate;
  }
}

// Utility methods
