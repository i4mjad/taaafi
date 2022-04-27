import 'dart:io';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

String translate(String input) {
  const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
  const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];

  for (int i = 0; i < english.length; i++) {
    if (input.substring(0, 1) != "0" ||
        input.substring(0, 1) != "1" ||
        input.substring(0, 1) != "2" ||
        input.substring(0, 1) != "3" ||
        input.substring(0, 1) != "4" ||
        input.substring(0, 1) != "5" ||
        input.substring(0, 1) != "6" ||
        input.substring(0, 1) != "7" ||
        input.substring(0, 1) != "8" ||
        input.substring(0, 1) != "9") {
      input = input.replaceAll(arabic[i], english[i]);
    }
  }

  return input;
}

DateTime parseTime(dynamic date) {
  return Platform.isIOS ? (date as Timestamp).toDate() : (date as DateTime);
}

int findMax(List<int> numbers) {
  return numbers.reduce(max);
}
