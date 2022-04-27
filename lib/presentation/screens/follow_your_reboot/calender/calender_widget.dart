import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:reboot_app_3/Model/Relapse.dart';
import 'package:reboot_app_3/Shared/constants/constants.dart';
import 'package:reboot_app_3/Shared/constants/textstyles_constants.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

import 'calender_data_model.dart';

class FollowUpData {
  var relapses = [];
  var watches = [];
  var masts = [];

  FollowUpData(this.relapses, this.watches, this.masts);
}

class FollowUpCalender extends StatelessWidget {
  FollowUpCalender({Key key}) : super(key: key);

  var daysArray = <Day>[];
  var oldRelapses = <DateTime>[];
  var oldWatches = <DateTime>[];
  var oldMasts = <DateTime>[];
  List<Day> getCalenderData(FollowUpData followUpData, dynamic resetDay) {
    FirebaseFirestore database = FirebaseFirestore.instance;
    final user = FirebaseAuth.instance.currentUser;

    final today = DateTime.now();

    var userPreviousStreak = 0;
    final regDate = user.metadata.creationTime;

    oldRelapses.clear();
    for (var strDate in followUpData.relapses) {
      final date = DateTime.parse(strDate);
      oldRelapses.add(date);
    }
    oldWatches.clear();
    for (var strDate in followUpData.watches) {
      final date = DateTime.parse(strDate);
      oldWatches.add(date);
    }
    oldMasts.clear();
    for (var strDate in followUpData.masts) {
      final date = DateTime.parse(strDate);
      oldMasts.add(date);
    }

    final userFirstDate = resetDay != null
        ? resetDay
        : regDate.add(Duration(days: userPreviousStreak));

    List<DateTime> calculateDaysInterval(DateTime startDate, DateTime endDate) {
      List<DateTime> days = [];
      for (int i = 0; i <= endDate.difference(startDate).inDays; i++) {
        days.add(startDate.add(Duration(days: i)));
      }
      return days;
    }

    for (var date in calculateDaysInterval(userFirstDate, today)) {
      final dateD = new DateTime(date.year, date.month, date.day);

      if (oldRelapses.contains(dateD)) {
        daysArray.add(new Day(type: "Relapse", date: date, color: Colors.red));
      } else if (oldWatches.contains(dateD) && !oldRelapses.contains(dateD)) {
        daysArray.add(
            new Day(type: "Watching Porn", date: date, color: Colors.purple));
      } else if (oldMasts.contains(dateD) && !oldRelapses.contains(dateD)) {
        daysArray.add(
            new Day(type: "Masturbating", date: date, color: Colors.orange));
      } else {
        daysArray
            .add(new Day(type: "Success", date: date, color: Colors.green));
      }
    }

    return daysArray;
  }

  @override
  Widget build(BuildContext context) {
    List masts;
    List relapses;
    List watches;
    return Container(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height * 0.35,
      decoration: BoxDecoration(
          color: mainGrayColor, borderRadius: BorderRadius.circular(15)),
      child: SfCalendar(
        onTap: (CalendarTapDetails details) {
          DateTime date = details.date;
          // dateChecker(date);
        },
        view: CalendarView.month,
        headerStyle: CalendarHeaderStyle(
            textAlign: TextAlign.center,
            backgroundColor: mainYellowColor,
            textStyle: kSubTitlesStyle),
        dataSource: CalenderDataSource(getCalenderData(
            CreateFollowUpData(relapses, watches, masts), null)),
        monthViewSettings: MonthViewSettings(
          agendaStyle: AgendaStyle(),
          appointmentDisplayMode: MonthAppointmentDisplayMode.indicator,
        ),
      ),
    );
  }

  FollowUpData CreateFollowUpData(
          List<dynamic> relapses, List<dynamic> watches, List<dynamic> masts) =>
      FollowUpData(relapses, watches, masts);
}
