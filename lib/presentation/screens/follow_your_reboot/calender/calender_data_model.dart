import 'dart:ui';

import 'package:reboot_app_3/data/models/CalenderDay.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

class CalenderDataSource extends CalendarDataSource {
  CalenderDataSource(List<CalenderDay> source) {
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
