import 'package:flutter/material.dart';

Future<DateTime?> getDateTime(BuildContext context) async {
  var selectedDate = await showDatePicker(
    context: context,
    initialDate: DateTime.now(),
    currentDate: DateTime.now(),
    firstDate: DateTime(DateTime.now().year - 1),
    lastDate: DateTime.now(),
  );

  return selectedDate;
}

DateTime getToday() {
  return DateTime.now();
}
