import 'package:flutter/material.dart';

Future<DateTime> getDateOfBirth(BuildContext context) async {
  var selectedDate = await showDatePicker(
    context: context,
    initialDate: DateTime.now(),
    currentDate: DateTime.now(),
    firstDate: DateTime(DateTime.now().year - 100),
    lastDate: DateTime.now(),
  );

  return selectedDate;
}

Future<DateTime> getStartingDate(BuildContext context) async {
  var selectedDate = await showDatePicker(
    context: context,
    initialDate: DateTime.now(),
    currentDate: DateTime.now(),
    firstDate: DateTime(DateTime.now().year - 100),
    lastDate: DateTime.now(),
  );

  return selectedDate;
}
