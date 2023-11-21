import 'package:reboot_app_3/presentation/screens/follow_your_reboot/widgets/followup_modal_bottomsheet_widgets.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:reboot_app_3/viewmodels/followup_viewmodel.dart';

String getTodaysDateString() {
  final DateTime now = DateTime.now();
  final DateFormat formatter = DateFormat('yyyy-MM-dd');
  final String today = formatter.format(now);
  return today;
}

bool dayWithinRange(DateTime firstDate, DateTime date) {
  final today = DateTime.now();
  return (date.isAfter(firstDate) || date.isAtSameMomentAs(firstDate)) &&
      (date.isBefore(today) || date.isAtSameMomentAs(today));
}

dateChecker(DateTime firstDate, DateTime date, BuildContext context,
    FollowUpViewModel followUpViewModel) {
  if (dayWithinRange(firstDate, date)) {
    final dateStr = date.toString().substring(0, 10);
    changeDateEvent(dateStr, context, followUpViewModel);
  } else {
    outOfRangeAlert(context);
  }
}
