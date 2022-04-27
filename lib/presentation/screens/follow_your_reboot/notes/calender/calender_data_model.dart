import 'dart:ui';

import 'package:syncfusion_flutter_calendar/calendar.dart';

import '../../follow_your_reboot_screen.dart';

class CalenderDataSource extends CalendarDataSource {
  CalenderDataSource(List<Day> source) {
    appointments = source;
  }

  @override
  String getSubject(int index) {
    return appointments[index].type;
  }

  @override
  DateTime getStartTime(int index) {
    return appointments[index].date;
  }

  @override
  DateTime getEndTime(int index) {
    return appointments[index].date;
  }

  @override
  Color getColor(int index) {
    return appointments[index].color;
  }

  @override
  bool isAllDay(int index) {
    return true;
  }
}
