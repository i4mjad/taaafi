import 'package:flutter/material.dart';

void newUserDialog(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
          topRight: Radius.circular(30.0), topLeft: Radius.circular(30.0)),
    ),
    builder: (context) {
      return;
    },
  );
}

Future<DateTime> getDateTime(BuildContext context) async {
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
