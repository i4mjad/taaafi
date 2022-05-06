import 'dart:core';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:reboot_app_3/Model/Relapse.dart';
import 'package:reboot_app_3/presentation/Screens/auth/login_screen.dart';
import 'package:reboot_app_3/shared/constants/constants.dart';
import 'package:reboot_app_3/shared/constants/textstyles_constants.dart';
import 'package:reboot_app_3/shared/localization/localization.dart';
import 'package:reboot_app_3/shared/localization/localization_services.dart';
import 'package:reboot_app_3/shared/services/routing/routes_names.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'calender/calender_data_model.dart';
import 'day_of_week_relapses/day_of_week_relapses_widget.dart';
import 'follow_your_reboot_services.dart';
import 'follow_your_reboot_widgets.dart';
import 'notes/notes_screen.dart';

class FollowYourRebootScreen extends StatefulWidget {
  const FollowYourRebootScreen({
    key,
  }) : super(key: key);

  @override
  _FollowYourRebootScreenState createState() => _FollowYourRebootScreenState();
}

class _FollowYourRebootScreenState extends State<FollowYourRebootScreen>
    with TickerProviderStateMixin {
  String lang;

  FirebaseFirestore database = FirebaseFirestore.instance;
  final user = FirebaseAuth.instance.currentUser;

  var resetDay;

  var userPreviousStreak = 0;
  var currentStreak = 0;
  var currentNoPornStreak = 0;
  var currentNoMastStreak = 0;

  String lastWatchOnly;
  String lastMastOnly;
  String lastRelapce;

  var userRelapses = [];
  var userWatchingWithoutMasturbating = [];
  var userMasturbatingWithoutWatching = [];

  var userFirstDayRecorded;

  var satRelapses = "";
  var sunRelapses = "";
  var monRelapses = "";
  var tueRelapses = "";
  var wedRelapses = "";
  var thuRelapses = "";
  var friRelapses = "";

  final TextEditingController newStreak = TextEditingController();

//TODO - TPUR. Method load userRelapses from the database
  void loadUserRelapces() async {
    final userData = database.collection('users').doc('${user.uid}');

    userData.snapshots().listen((snapshot) async {
      //get the previous streak
      if (snapshot.exists == true &&
          snapshot.data().containsKey('userPreviousStreak') &&
          snapshot.get("userPreviousStreak") != null) {
        //exist user, load data
        // TODO - TPUR01
        final previousStreak = await snapshot.get("userPreviousStreak");
        setState(() {
          userPreviousStreak = previousStreak;
        });

        //check if user have relapses before
        if (snapshot.data().containsKey('userRelapses') &&
            snapshot.get("userPreviousStreak") != null) {
          //

          //TODO - TPUR01-01-LOGIC
          setState(() {
            userRelapses.clear();
            for (var date in snapshot.get("userRelapses")) {
              userRelapses.add(translate(date));
            }
          });



          final today = DateTime.now();
          final regDate = user.metadata.creationTime;

          var userFirstDate;

          //TODO - TPUR01-01-IF01
          if (snapshot.data().containsKey("resetedDate")) {
            //TODO - TPUR01-01-IF01-01
            final userFirstDateTimeStamp = await snapshot.get("resetedDate");

            DateTime userRefDate = parseTime(userFirstDateTimeStamp);

            setState(() {
              this.resetDay = userRefDate;
              this.userFirstDayRecorded = userRefDate;
            });
          } else {
            //TODO - TPUR01-01-IF01-02
            userFirstDate =
                regDate.add(Duration(days: userPreviousStreak.toInt()));

            setState(() {
              userFirstDayRecorded = userFirstDate;
            });
          }

          //TODO - TPUR01-01-IF02
          if (userRelapses.length > 0) {
            //TODO - TPUR01-01-IF02-01
            //get the last relapse
            userRelapses.sort((a, b) {
              return a.compareTo(b);
            });
            final lastRelapseDayStr = userRelapses[userRelapses.length - 1];
            //make a date from the last relapse
            final lastRelapseDay = DateTime.parse(lastRelapseDayStr);
            //calculate the current streak by making time interval between today and the last
            final calcCurrentStreak =
                today.difference(lastRelapseDay ?? userFirstDate);
            setState(() {
              var calcStreak = calcCurrentStreak.inDays == 0
                  ? calcCurrentStreak.inDays
                  : calcCurrentStreak.inDays - 1;

              this.currentStreak = calcStreak;
              this.lastRelapce = lastRelapseDayStr;
            });
          }
        } else {
          //TODO - TPUR01-02
          if (snapshot.data().containsKey("resetedDate") != false) {
            //TODO - TPUR01-02-01
            final today = DateTime.now();
            final userFirstDateTimeStamp = await snapshot.get("resetedDate");

            DateTime userRefDate = parseTime(userFirstDateTimeStamp);

            final streak = userRefDate.difference(today).inDays;
            setState(() {
              this.currentStreak = (streak * -1);
              resetDay = userRefDate;
            });
          } else {
            //TODO - TPUR01-02-02
            final today = DateTime.now();
            final regDate = user.metadata.creationTime;
            final userFirstDate =
                regDate.subtract(Duration(days: userPreviousStreak));

            final streak = userFirstDate.difference(today).inDays;
            setState(() {
              this.currentStreak = (streak * -1);
              this.userFirstDayRecorded = userFirstDate;
            });
          }
        }
      } else {
        //TODO - TPUR02
        if ((snapshot.exists == true &&
            snapshot.get("userPreviousStreak") == null)) {
          //TODO - TPUR02-01
          newUserDialog();
        } else {
          //TODO - TPUR02-02
          if (snapshot.exists == false) {
            newUserDialog();
          }
        }
      }
    });
  }

//TODO -TPUW. Method load userWatchingWithoutMasturbating from the database
  void loadUserWatchesOnly() async {
    final userData = database.collection('users').doc('${user.uid}');

    userData.snapshots().listen((snapshot) {
      //TODO - TPUW01
      if (snapshot.exists == true &&
          snapshot.data().containsKey("userWatchingWithoutMasturbating")) {
        //TODO - TPUW01-LOGIC
        setState(() {
          userWatchingWithoutMasturbating.clear();
          for (var date in snapshot.get("userWatchingWithoutMasturbating")) {
            userWatchingWithoutMasturbating.add(translate(date));
          }
        });

        final today = DateTime.now();

        if (userWatchingWithoutMasturbating.length >= 1) {
          //TODO - TPUW01-01
          //get the last relapse
          userWatchingWithoutMasturbating.sort((a, b) {
            return a.compareTo(b);
          });
          final lastWatchDayStr = userWatchingWithoutMasturbating[
              userWatchingWithoutMasturbating.length - 1];
          //make a date from the last relapse
          final lastWatchDay =
              DateTime.parse(lastWatchDayStr.toString().trim());
          //calculate the current streak by making time interval between today and the last
          final calcCurrentStreak = today.difference(lastWatchDay);
          setState(() {
            var calcStreak = calcCurrentStreak.inDays == 0
                ? calcCurrentStreak.inDays
                : calcCurrentStreak.inDays - 1;

            this.currentNoPornStreak = calcStreak;
          });
        } else {
          //TODO - TPUW01-02
          //array has one value
          setState(() {
            currentNoPornStreak = currentStreak;
          });
        }
      }

      //TODO - TPUW02
      else {
        setState(() {
          currentNoPornStreak = currentStreak;
        });
      }
    });
  }

//TODO -TPUM. Method load userMasturbatingWithoutWatching from the database
  void loadUserMastsOnly() async {
    final userData = database.collection('users').doc('${user.uid}');

    userData.snapshots().listen((snapshot) {
      //check if user have watches before
      if (snapshot.data().containsKey('userMasturbatingWithoutWatching')) {
        //TODO - TPUM01
        //TODO - TPUM01-LOGIC

        setState(() {
          userMasturbatingWithoutWatching.clear();
          for (var date in snapshot.get("userMasturbatingWithoutWatching")) {
            userMasturbatingWithoutWatching.add(translate(date));
          }
        });

        final today = DateTime.now();

        if (userMasturbatingWithoutWatching.length >= 1) {
          //TODO - TPUM01-01
          //get the last relapse

          //sort by date
          userMasturbatingWithoutWatching.sort((a, b) {
            return a.compareTo(b);
          });

          final lastMastDayStr = userMasturbatingWithoutWatching[
              userMasturbatingWithoutWatching.length - 1];

          final lastMastDay = DateTime.parse(lastMastDayStr.toString().trim());

          final calcCurrentStreak = today.difference(lastMastDay);

          setState(() {
            this.lastMastOnly = lastMastDayStr;
            var calcStreak = calcCurrentStreak.inDays == 0
                ? calcCurrentStreak.inDays
                : calcCurrentStreak.inDays - 1;
            this.currentNoMastStreak = calcStreak;
          });
        } else {
          //TODO - TPUM01-02
          setState(() {
            currentNoMastStreak = currentStreak;
          });
        }
      }

      //no mast
      else {
        //TODO - TPUM02
        setState(() {
          currentNoMastStreak = currentStreak;
        });
      }
    });
  }

//TODO -4. Method crating List<Day> for calender and adding the days to it
  List<Day> getCalenderData() {
    var daysArray = <Day>[];
    var oldRelapses = <DateTime>[];
    var oldWatches = <DateTime>[];
    var oldMasts = <DateTime>[];

    final today = DateTime.now();

    var userPreviousStreak = 0;
    final regDate = user.metadata.creationTime;

    oldRelapses.clear();
    for (var strDate in this.userRelapses) {
      final date = DateTime.parse(strDate);
      oldRelapses.add(date);
    }
    oldWatches.clear();
    for (var strDate in this.userWatchingWithoutMasturbating) {
      final date = DateTime.parse(strDate);
      oldWatches.add(date);
    }
    oldMasts.clear();
    for (var strDate in this.userMasturbatingWithoutWatching) {
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

  DayOfWeekRelapses dailyStatistics(List<dynamic> userRelapses) {
    var sat = [];
    var sun = [];
    var mon = [];
    var tue = [];
    var wed = [];
    var thu = [];
    var fri = [];

    for (var strDate in userRelapses) {
      final date = DateTime.parse(strDate);
      final dayOfWeek = date.weekday;

      if (dayOfWeek == 7) {
        sun.add(date);
      } else if (dayOfWeek == 1) {
        mon.add(date);
      } else if (dayOfWeek == 2) {
        tue.add(date);
      } else if (dayOfWeek == 3) {
        wed.add(date);
      } else if (dayOfWeek == 4) {
        thu.add(date);
      } else if (dayOfWeek == 5) {
        fri.add(date);
      } else if (dayOfWeek == 6) {
        sat.add(date);
      }
    }

    final satLength = (sat.length).toString();
    final sunLength = (sun.length).toString();
    final monLength = (mon.length).toString();
    final tueLength = (tue.length).toString();
    final wedLength = (wed.length).toString();
    final thuLength = (thu.length).toString();
    final friLength = (fri.length).toString();

    final dayOfWeekRelapses = DayOfWeekRelapses(satLength, sunLength, monLength,
        tueLength, wedLength, thuLength, friLength);
    return dayOfWeekRelapses;
  }

  List<int> generalStatistics() {
    final _userPreviousStreak = userPreviousStreak.toInt();

    final DateTime today = DateTime.now();
    final DateTime todayE = DateTime(today.year, today.month, today.day);

    var relapsesInDate = [];

    if (userRelapses.length > 0) {
      relapsesInDate.clear();
      for (var i in userRelapses) {
        final date = DateTime.parse(i);
        relapsesInDate.add(date);
      }
    }
    if (userRelapses.length != 0) {
      relapsesInDate.add(todayE);
    }

    final regDate = user.metadata.creationTime;
    final userFirstDate = resetDay == null
        ? regDate.subtract(Duration(days: _userPreviousStreak.toInt()))
        : resetDay;

    List<int> differences = [];

    if (relapsesInDate.length != 0) {
      for (var i in relapsesInDate) {
        if (relapsesInDate[0] == i) {
          final firstPeriod = i.difference(userFirstDate).inDays;
          differences.add(firstPeriod + 1);
        } else {
          final period = i
              .difference(relapsesInDate[relapsesInDate.indexOf(i) - 1])
              .inDays;
          final realPeriod = period - 1;
          differences.add(realPeriod);
        }
      }
    }

    differences.removeAt(differences.length - 1);

    return differences;
  }

  double relapsesAverage(int averageNumber) {
    //get the number of relapses
    var relapsesCount = generalStatistics().length;
    //get the total days since beginning
    var totalDays =
        (generalStatistics().reduce((a, b) => a + b) + relapsesCount) - 2;
    //get number of the specified periods 'averageNumber'
    var averagePeriods = totalDays / averageNumber;
    //return the requested average
    return double.parse((relapsesCount / averagePeriods).toStringAsFixed(2));
  }

  @override
  void initState() {
    super.initState();
    loadUserRelapces();
    loadUserWatchesOnly();
    loadUserMastsOnly();
    getCalenderData();

    LocaleService.getSelectedLocale().then((value) {
      setState(() {
        lang = value;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: seconderyColor,
        body: Padding(
          padding: EdgeInsets.only(top: 96.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 16, left: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppLocalizations.of(context)
                            .translate('follow-your-reboot'),
                        style:
                            kPageTitleStyle.copyWith(height: 1, fontSize: 28),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => NotesScreen()));
                        },
                        child: Icon(
                          Iconsax.archive_1,
                          size: 32,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 32),
                followUpSection(context),
                //FollowUpSection(),
                Padding(
                  padding: EdgeInsets.only(right: 16, left: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        //mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text(
                              AppLocalizations.of(context)
                                  .translate('reboot-calender'),
                              style: kSubTitlesStyle),
                          SizedBox(
                            height: 8,
                          ),
                          Container(
                            width: MediaQuery.of(context).size.width,
                            height: MediaQuery.of(context).size.height * 0.35,
                            decoration: BoxDecoration(
                                color: mainGrayColor,
                                borderRadius: BorderRadius.circular(15)),
                            child: SfCalendar(
                              onTap: (CalendarTapDetails details) {
                                DateTime date = details.date;
                                dateChecker(date);
                              },
                              view: CalendarView.month,
                              headerStyle: CalendarHeaderStyle(
                                  textAlign: TextAlign.center,
                                  backgroundColor: mainYellowColor,
                                  textStyle: kSubTitlesStyle),
                              dataSource: CalenderDataSource(getCalenderData()),
                              monthViewSettings: MonthViewSettings(
                                agendaStyle: AgendaStyle(),
                                appointmentDisplayMode:
                                    MonthAppointmentDisplayMode.indicator,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 12,
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        //mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text(
                              AppLocalizations.of(context)
                                  .translate('relapses-by-day-of-week'),
                              style: kSubTitlesStyle),
                          SizedBox(
                            height: 8,
                          ),
                          Builder(
                            builder: (BuildContext context) {
                              if (userRelapses.length == 0) {
                                return NoRelapses();
                              } else {
                                return DayOfWeekRelapsesWidget(
                                    dailyStatistics(userRelapses));
                              }
                            },
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 12,
                      ),
                      Text(AppLocalizations.of(context).translate('streaks'),
                          style: kSubTitlesStyle),
                      SizedBox(
                        height: 12,
                      ),
                      Builder(
                        builder: (BuildContext context) {
                          if (userRelapses.length == 0) {
                            return NoRelapses();
                          } else {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(12),
                                      width:
                                          (MediaQuery.of(context).size.width -
                                                      40) /
                                                  2 -
                                              6,
                                      height:
                                          MediaQuery.of(context).size.height *
                                              0.22,
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.1),
                                        borderRadius:
                                            BorderRadius.circular(12.5),
                                      ),
                                      child: Column(
                                        children: [
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Align(
                                                alignment: lang == 'ar'
                                                    ? Alignment.topRight
                                                    : Alignment.topLeft,
                                                child: CircleAvatar(
                                                  minRadius: 18,
                                                  maxRadius: 20,
                                                  backgroundColor: Colors.green
                                                      .withOpacity(0.3),
                                                  child: Icon(
                                                    Iconsax.medal,
                                                    color: Colors.green,
                                                  ),
                                                ),
                                              ),
                                              Padding(
                                                padding: EdgeInsets.only(
                                                    right: 8.0,
                                                    top: 3,
                                                    left: 8),
                                                child: Text(
                                                  AppLocalizations.of(context)
                                                      .translate(
                                                          'highest-streak'),
                                                  style:
                                                      kSubTitlesStyle.copyWith(
                                                          fontSize: 16,
                                                          color: Colors.green,
                                                          height: 1),
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(
                                            height: 20,
                                          ),
                                          Text(
                                            findMax(generalStatistics())
                                                .toString(),
                                            style: kPageTitleStyle.copyWith(
                                                color: Colors.green),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: EdgeInsets.all(12),
                                      width:
                                          (MediaQuery.of(context).size.width -
                                                      40) /
                                                  2 -
                                              6,
                                      height:
                                          MediaQuery.of(context).size.height *
                                              0.22,
                                      decoration: BoxDecoration(
                                        color:
                                            Colors.redAccent.withOpacity(0.1),
                                        borderRadius:
                                            BorderRadius.circular(12.5),
                                      ),
                                      child: Column(
                                        children: [
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Align(
                                                alignment: lang == 'ar'
                                                    ? Alignment.topRight
                                                    : Alignment.topLeft,
                                                child: CircleAvatar(
                                                  minRadius: 18,
                                                  maxRadius: 20,
                                                  backgroundColor: Colors
                                                      .redAccent
                                                      .withOpacity(0.3),
                                                  child: Icon(
                                                    Iconsax.ranking,
                                                    color: Colors.red,
                                                  ),
                                                ),
                                              ),
                                              Padding(
                                                padding: EdgeInsets.only(
                                                    right: 8.0,
                                                    top: 3,
                                                    left: 8),
                                                child: Text(
                                                  AppLocalizations.of(context)
                                                      .translate(
                                                          'relapses-count'),
                                                  style:
                                                      kSubTitlesStyle.copyWith(
                                                          fontSize: 16,
                                                          color: Colors.red,
                                                          height: 1),
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(
                                            height: 20,
                                          ),
                                          Text(
                                              (generalStatistics().length)
                                                  .toString(),
                                              style: kPageTitleStyle.copyWith(
                                                  color: Colors.red)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(
                                  height: 12,
                                ),
                                Container(
                                  padding: EdgeInsets.all(20),
                                  width: MediaQuery.of(context).size.width,
                                  height:
                                      MediaQuery.of(context).size.height * 0.25,
                                  decoration: BoxDecoration(
                                    color: Colors.brown.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(12.5),
                                  ),
                                  child: Column(
                                    children: [
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Align(
                                            alignment: Alignment.topRight,
                                            child: CircleAvatar(
                                              minRadius: 18,
                                              maxRadius: 20,
                                              backgroundColor:
                                                  Colors.brown.withOpacity(0.3),
                                              child: Icon(
                                                Iconsax.chart,
                                                color: Colors.brown,
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding: EdgeInsets.only(
                                                right: 8.0, top: 3, left: 8),
                                            child: Text(
                                              AppLocalizations.of(context)
                                                  .translate(
                                                      'relapses-average'),
                                              style: kSubTitlesStyle.copyWith(
                                                  fontSize: 16,
                                                  color: Colors.brown,
                                                  height: 1),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceAround,
                                        children: [
                                          Column(
                                            children: [
                                              Text(
                                                generalStatistics().reduce(
                                                            (a, b) => a + b) >=
                                                        7
                                                    ? relapsesAverage(7)
                                                        .toString()
                                                    : "0.00",
                                                style: kSubTitlesStyle.copyWith(
                                                    fontSize: 24,
                                                    color: Colors.brown,
                                                    fontWeight:
                                                        FontWeight.w400),
                                              ),
                                              Text(
                                                AppLocalizations.of(context)
                                                    .translate("7-days"),
                                                style: kSubTitlesStyle.copyWith(
                                                    color: Colors.brown,
                                                    fontSize: 14,
                                                    fontWeight:
                                                        FontWeight.w700),
                                              )
                                            ],
                                          ),
                                          Column(
                                            children: [
                                              Text(
                                                generalStatistics().reduce(
                                                            (a, b) => a + b) >=
                                                        28
                                                    ? relapsesAverage(28)
                                                        .toString()
                                                    : "0.00",
                                                style: kSubTitlesStyle.copyWith(
                                                    fontSize: 24,
                                                    color: Colors.brown,
                                                    fontWeight:
                                                        FontWeight.w400),
                                              ),
                                              Text(
                                                AppLocalizations.of(context)
                                                    .translate("28-days"),
                                                style: kSubTitlesStyle.copyWith(
                                                    color: Colors.brown,
                                                    fontSize: 14,
                                                    fontWeight:
                                                        FontWeight.w700),
                                              )
                                            ],
                                          ),
                                          Column(
                                            children: [
                                              Text(
                                                generalStatistics().reduce(
                                                            (a, b) => a + b) >=
                                                        90
                                                    ? relapsesAverage(90)
                                                        .toString()
                                                    : "0.00",
                                                style: kSubTitlesStyle.copyWith(
                                                    fontSize: 24,
                                                    color: Colors.brown,
                                                    fontWeight:
                                                        FontWeight.w400),
                                              ),
                                              Text(
                                                AppLocalizations.of(context)
                                                    .translate("90-days"),
                                                style: kSubTitlesStyle.copyWith(
                                                    color: Colors.brown,
                                                    fontSize: 14,
                                                    fontWeight:
                                                        FontWeight.w700),
                                              )
                                            ],
                                          ),
                                        ],
                                      ),
                                      SizedBox(
                                        height: 4,
                                      ),
                                      Padding(
                                        padding: EdgeInsets.all(4.0),
                                        child: Container(
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Flexible(
                                                  child: Text(
                                                AppLocalizations.of(context)
                                                    .translate(
                                                        "relapses-average-p"),
                                                textAlign: TextAlign.center,
                                                style: kSubTitlesStyle.copyWith(
                                                    color: Colors.brown,
                                                    fontSize: 12,
                                                    fontWeight:
                                                        FontWeight.w400),
                                              ))
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }
                        },
                      ),
                      SizedBox(
                        height: 40,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ));
  }

  Container followUpSection(BuildContext context) {
    return Container(
      child: Padding(
        padding: EdgeInsets.only(right: 16.0, left: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context).translate('current-streak'),
                style: kSubTitlesStyle),
            SizedBox(
              height: 8,
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: MediaQuery.of(context).size.width * 0.27,
                  height: 150,
                  decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.20),
                      borderRadius: BorderRadius.circular(15)),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Text(
                              this.currentStreak.toString(),
                              style: kPageTitleStyle.copyWith(
                                color: Colors.red,
                                fontSize: 35,
                              ),
                            ),
                            Text(
                              AppLocalizations.of(context)
                                  .translate('free-relapse-days'),
                              style: kSubTitlesStyle.copyWith(
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 8,
                ),
                Container(
                  width: MediaQuery.of(context).size.width * 0.27,
                  height: 150,
                  decoration: BoxDecoration(
                      color: Colors.orangeAccent.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(15)),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Text(
                              this.currentNoMastStreak.toString(),
                              style: kPageTitleStyle.copyWith(
                                  color: Colors.orangeAccent),
                            ),
                            Text(
                              AppLocalizations.of(context)
                                  .translate('free-mast-days'),
                              style: kSubTitlesStyle.copyWith(
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 8,
                ),
                Container(
                  width: MediaQuery.of(context).size.width * 0.27,
                  height: 150,
                  decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(15)),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Text(
                              this.currentNoPornStreak.toString(),
                              style: kPageTitleStyle.copyWith(
                                  color: Colors.purple),
                            ),
                            Text(
                              AppLocalizations.of(context)
                                  .translate('free-porn-days'),
                              style: kSubTitlesStyle.copyWith(
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(
              height: 16,
            ),
            Container(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      changeDateEvent(getTodaysDateString());
                    },
                    child: Container(
                      width: (MediaQuery.of(context).size.width),
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            spreadRadius: .25,
                            blurRadius: 7,
                            offset: Offset(0, 2), // changes position of shadow
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            AppLocalizations.of(context)
                                .translate('daily-follow-up'),
                            style: kSubTitlesStyle.copyWith(
                                fontSize: 20,
                                color: primaryColor,
                                fontWeight: FontWeight.w400,
                                height: 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String getTodaysDateString() {
    final DateTime now = DateTime.now();
    final DateFormat formatter = DateFormat('yyyy-MM-dd');
    final String today = formatter.format(now);
    return today;
  }

//TODO - This needed to be refactored to not depend on the variable in the widget
  void dateChecker(DateTime date) {
    //get the range of the dates from the first recorded date until today

    //check if the date clicked is within the range, if yes pass it to the function, if not inform the user
    if (dayWithinRange(date)) {
      final dateStr = date.toString().substring(0, 11);
      changeDateEvent(dateStr);
    } else {
      outOfRangeAlert(context);
    }
  }

  bool dayWithinRange(DateTime date) {
    final today = DateTime.now();

    return date.isAfter(resetDay != null ? resetDay : userFirstDayRecorded) &&
        date.isBefore(today);
  }

  void changeDateEvent(String date) async {
    final trimedDate = date.trim();
    showModalBottomSheet(
        context: context,
        builder: (context) {
          return Padding(
            padding: EdgeInsets.only(left: 20.0, right: 20, top: 8, bottom: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: 5,
                      width: MediaQuery.of(context).size.width * 0.1,
                      color: Colors.black12,
                    )
                  ],
                ),
                SizedBox(
                  height: 12,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      trimedDate,
                      style: kPageTitleStyle.copyWith(fontSize: 26),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: Icon(
                        CupertinoIcons.xmark_circle_fill,
                        color: Colors.black26,
                        size: 32,
                      ),
                    )
                  ],
                ),
                SizedBox(
                  height: 8,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppLocalizations.of(context)
                          .translate('how-did-you-perform-in-this-day'),
                      style: kPageTitleStyle.copyWith(
                          fontSize: 18,
                          color: Colors.grey,
                          fontWeight: FontWeight.normal),
                    ),
                  ],
                ),
                SizedBox(
                  height: 8,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    //relapse
                    GestureDetector(
                      onTap: () {
                        //TODO - Take all of this logic out of here
                        setState(() {
                          if (!userRelapses.contains(trimedDate)) {
                            //
                            userRelapses.add(trimedDate);
                            database.collection("users").doc(user.uid).update({
                              "userRelapses": userRelapses,
                            });
                          }

                          if (!userMasturbatingWithoutWatching
                              .contains(trimedDate)) {
                            userMasturbatingWithoutWatching.add(trimedDate);
                            database.collection("users").doc(user.uid).update({
                              "userMasturbatingWithoutWatching":
                                  userMasturbatingWithoutWatching,
                            });
                          }

                          if (!userWatchingWithoutMasturbating
                              .contains(trimedDate)) {
                            userWatchingWithoutMasturbating.add(trimedDate);
                            database.collection("users").doc(user.uid).update({
                              "userWatchingWithoutMasturbating":
                                  userWatchingWithoutMasturbating,
                            });
                          }
                        });
                        Navigator.pop(context);
                      },
                      child: Container(
                        width: MediaQuery.of(context).size.width / 2.5,
                        height: 100,
                        decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12.5),
                            border: Border.all(color: Colors.red)),
                        child: Center(
                          child: Text(
                            AppLocalizations.of(context).translate("relapse"),
                            style: kSubTitlesStyle.copyWith(
                                color: Colors.red,
                                fontSize: 16,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ),
                    //success
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          userWatchingWithoutMasturbating.remove(trimedDate);
                          userMasturbatingWithoutWatching.remove(trimedDate);
                          userRelapses.remove(trimedDate);
                        });

                        final userData =
                            database.collection("users").doc(user.uid);

                        userData.update({
                          "userRelapses": userRelapses,
                          "userWatchingWithoutMasturbating":
                              userWatchingWithoutMasturbating,
                          "userMasturbatingWithoutWatching":
                              userMasturbatingWithoutWatching
                        });

                        if (userRelapses.length == 0) {
                          userData
                              .update({"userRelapses": FieldValue.delete()});
                        }

                        if (userWatchingWithoutMasturbating.length == 0) {
                          userData.update({
                            "userWatchingWithoutMasturbating":
                                FieldValue.delete()
                          });
                        }

                        if (userMasturbatingWithoutWatching.length == 0) {
                          userData.update({
                            "userMasturbatingWithoutWatching":
                                FieldValue.delete()
                          });
                        }

                        Navigator.pop(context);
                        //
                      },
                      child: Container(
                        width: MediaQuery.of(context).size.width / 2.5,
                        height: 100,
                        decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12.5),
                            border: Border.all(color: Colors.green)),
                        child: Center(
                          child: Text(
                            AppLocalizations.of(context).translate("free-day"),
                            style: kSubTitlesStyle.copyWith(
                                color: Colors.green,
                                fontWeight: FontWeight.w600,
                                fontSize: 16),
                          ),
                        ),
                      ),
                    )
                  ],
                ),
                SizedBox(
                  height: 18,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    //only porn
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          userWatchingWithoutMasturbating.add(trimedDate);
                          database.collection("users").doc(user.uid).update({
                            "userWatchingWithoutMasturbating":
                                userWatchingWithoutMasturbating
                          });
                        });
                        Navigator.pop(context);
                      },
                      child: Container(
                        width: MediaQuery.of(context).size.width / 2.5,
                        height: 100,
                        decoration: BoxDecoration(
                            color: Colors.deepPurple.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12.5),
                            border: Border.all(color: Colors.deepPurple)),
                        child: Center(
                          child: Text(
                            AppLocalizations.of(context).translate("porn-only"),
                            textAlign: TextAlign.center,
                            style: kSubTitlesStyle.copyWith(
                                color: Colors.deepPurple,
                                fontSize: 16,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ),
                    //only mast
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          userMasturbatingWithoutWatching.add(trimedDate);
                          database.collection("users").doc(user.uid).update({
                            "userMasturbatingWithoutWatching":
                                userMasturbatingWithoutWatching
                          });
                        });
                        Navigator.pop(context);
                      },
                      child: Container(
                        width: MediaQuery.of(context).size.width / 2.5,
                        height: 100,
                        decoration: BoxDecoration(
                            color: Colors.orangeAccent.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12.5),
                            border: Border.all(color: Colors.orangeAccent)),
                        child: Center(
                          child: Text(
                            AppLocalizations.of(context).translate("mast-only"),
                            textAlign: TextAlign.center,
                            style: kSubTitlesStyle.copyWith(
                                color: Colors.orangeAccent,
                                fontWeight: FontWeight.w600,
                                fontSize: 16),
                          ),
                        ),
                      ),
                    )
                  ],
                ),
                SizedBox(
                  height: 20,
                ),
              ],
            ),
          );
        });
  }

//TODO - We need to slightly change the model of the data, userFirstDate indtead of userPreviousStreak
  void newUserDialog() {
    // set up the button
    Widget confirmExistStreakButton = TextButton(
      child: Text(
        AppLocalizations.of(context).translate('new-user-dialog-start-button'),
        style: kSubTitlesStyle.copyWith(color: primaryColor, fontSize: 18),
      ),
      onPressed: () {
        var _tempPreviousStreak = int.parse(newStreak.text.trim());
        setState(() {
          database.collection('users').doc('${user.uid}').set({
            "creationTime": user.metadata.creationTime,
            "uid": user.uid,
            "userPreviousStreak": _tempPreviousStreak,
          });
        });
        Navigator.of(context).pushNamed(followYourReboot);
      },
    );

    Widget newBegginingButton = TextButton(
      child: Text(
        AppLocalizations.of(context)
            .translate('new-user-dialog-new-start-button'),
        style: kSubTitlesStyle.copyWith(color: Colors.grey, fontSize: 18),
      ),
      onPressed: () {
        setState(() {
          database.collection('users').doc('${user.uid}').set({
            "creationTime": user.metadata.creationTime,
            "uid": user.uid,
            "userPreviousStreak": 0
          });
        });
        Navigator.pop(context);
      },
    );

    Widget numberField = TextField(
        controller: newStreak,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          prefixIcon: Icon(
            CupertinoIcons.number,
            color: primaryColor,
          ),
          border: InputBorder.none,
          hintText: AppLocalizations.of(context)
              .translate('new-user-dialog-hint-test-field'),
          hintStyle: kSubTitlesStyle.copyWith(
              fontSize: 12, color: Colors.grey, height: 1),
          contentPadding: EdgeInsets.only(left: 12, right: 12),
        ));

    // set up the AlertDialog
    Widget alert = AlertDialog(
      title: Text(
        AppLocalizations.of(context).translate('new-user-dialog-title'),
        style: kSubTitlesStyle.copyWith(color: primaryColor, fontSize: 14),
      ),
      content: Text(
          AppLocalizations.of(context).translate('new-user-dialog-content'),
          style: kSubTitlesStyle.copyWith(color: Colors.black, fontSize: 14)),
      actions: [
        numberField,
        confirmExistStreakButton,
        newBegginingButton,
      ],
    );

    // show the dialog
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }
}

class NoRelapses extends StatelessWidget {
  const NoRelapses({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height * 0.10,
      decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12.5)),
      child: Center(
        child: Text(
          AppLocalizations.of(context).translate("no-relapses"),
          style: kSubTitlesStyle.copyWith(color: Colors.green, fontSize: 18),
        ),
      ),
    );
  }
}

class FollowYourRebootScreenAuthenticationWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final User firebaseUser = context.watch<User>();

    if (firebaseUser != null) {
      return FollowYourRebootScreen();
    } else {
      return LoginScreen();
    }
  }
}
