import 'dart:core';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:reboot_app_3/presentation/Screens/auth/login_screen.dart';
//import 'package:reboot_app_3/presentation/screens/follow_your_reboot/follow_up_section.dart';
import 'package:reboot_app_3/shared/components/bottom_navbar.dart';
import 'package:reboot_app_3/shared/constants/constants.dart';
import 'package:reboot_app_3/shared/constants/textstyles_constants.dart';
import 'package:reboot_app_3/shared/localization/localization.dart';
import 'package:reboot_app_3/shared/localization/localization_services.dart';
import 'package:reboot_app_3/shared/services/routing/routes_names.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'follow_your_reboot_services.dart';
import 'follow_your_reboot_widgets.dart';
import 'notes/calender/calender_data_model.dart';
import 'notes/notes_screen.dart';

class Day {
  String type;
  DateTime date;
  MaterialColor color;

  Day({this.type, this.date, this.color});
}

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
  var hasOldData = false;

  var satRelapses = "";
  var sunRelapses = "";
  var monRelapses = "";
  var tueRelapses = "";
  var wedRelapses = "";
  var thuRelapses = "";
  var friRelapses = "";

  final TextEditingController newStreak = TextEditingController();

//TODO - 1. Method load userRelapses from the database
  void loadUserRelapces() async {
    final userData = database.collection('users').doc('${user.uid}');

    userData.snapshots().listen((snapshot) async {
      //get the previous streak
      if (snapshot.exists == true &&
          snapshot.data().containsKey('userPreviousStreak') &&
          snapshot.get("userPreviousStreak") != null) {
        //exist user, load data

        final previousStreak = await snapshot.get("userPreviousStreak");
        setState(() {
          userPreviousStreak = previousStreak;
        });

        //check if user have relapses before
        if (snapshot.data().containsKey('userRelapses') &&
            snapshot.get("userPreviousStreak") != null) {
          setState(() {
            userRelapses.clear();
            for (var date in snapshot.get("userRelapses")) {
              userRelapses.add(translate(date));
            }
          });

          dailyStatistics();

          final today = DateTime.now();
          final regDate = user.metadata.creationTime;

          var userFirstDate;

          if (snapshot.data().containsKey("resetedDate")) {
            final userFirstDateTimeStamp = await snapshot.get("resetedDate");

            DateTime userRefDate = parseTime(userFirstDateTimeStamp);

            setState(() {
              this.resetDay = userRefDate;
              this.userFirstDayRecorded = userRefDate;
            });
          } else {
            userFirstDate =
                regDate.add(Duration(days: userPreviousStreak.toInt()));

            setState(() {
              userFirstDayRecorded = userFirstDate;
            });
          }

          if (userRelapses.length > 0) {
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
          //dose not have old relapses, ether he is reseted the data or he have no relapses at all, so use other calc method

          if (snapshot.data().containsKey("resetedDate") != false) {
            final today = DateTime.now();
            final userFirstDateTimeStamp = await snapshot.get("resetedDate");

            DateTime userRefDate = parseTime(userFirstDateTimeStamp);

            final streak = userRefDate.difference(today).inDays;
            setState(() {
              this.currentStreak = (streak * -1);
              resetDay = userRefDate;
            });
          } else {
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
      }

      //new user or have old data
      else {
        if ((snapshot.exists == true &&
            snapshot.get("userPreviousStreak") == null)) {
          performNewUserDialog();
        } else {
          if (hasOldData == false && snapshot.exists == false) {
            performNewUserDialog();
          }
        }
      }
    });
  }

//TODO -2. Method load userWatchingWithoutMasturbating from the database
  void loadUserNoPorn() async {
    final userData = database.collection('users').doc('${user.uid}');

    userData.snapshots().listen((snapshot) {
      if (snapshot.exists == true &&
          snapshot.data().containsKey("userWatchingWithoutMasturbating")) {
        setState(() {
          userWatchingWithoutMasturbating.clear();
          for (var date in snapshot.get("userWatchingWithoutMasturbating")) {
            userWatchingWithoutMasturbating.add(translate(date));
          }
        });

        final today = DateTime.now();

        if (userWatchingWithoutMasturbating.length >= 1) {
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
          //array has one value
          setState(() {
            currentNoPornStreak = currentStreak;
          });
        }
      } else {
        setState(() {
          currentNoPornStreak = currentStreak;
        });
      }
    });
  }

//TODO -3. Method load userWatchingWithoutMasturbating from the database
  void loadUserNoMasts() async {
    final userData = database.collection('users').doc('${user.uid}');

    userData.snapshots().listen((snapshot) {
      //check if user have watches before
      if (snapshot.data().containsKey('userMasturbatingWithoutWatching')) {
        //add the dates to the array

        setState(() {
          userMasturbatingWithoutWatching.clear();
          for (var date in snapshot.get("userMasturbatingWithoutWatching")) {
            userMasturbatingWithoutWatching.add(translate(date));
          }
        });

        final today = DateTime.now();

        //geting the current streak if

        if (userMasturbatingWithoutWatching.length >= 1) {
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
          setState(() {
            currentNoMastStreak = currentStreak;
          });
        }
      }

      //no mast
      else {
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

  dailyStatistics() async {
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
    setState(() {
      satRelapses = satLength;
      sunRelapses = sunLength;
      monRelapses = monLength;
      tueRelapses = tueLength;
      wedRelapses = wedLength;
      thuRelapses = thuLength;
      friRelapses = friLength;
    });
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
    getCalenderData();
    loadUserRelapces();
    loadUserNoPorn();
    loadUserNoMasts();
    dailyStatistics();

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
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(
                          context,
                          MaterialPageRoute(
                              builder: (context) => NavigationBar()));
                    },
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(
                              lang != "ar"
                                  ? Iconsax.arrow_left
                                  : Iconsax.arrow_right,
                              size: 28,
                            ),
                            SizedBox(width: 8),
                            Text(
                              AppLocalizations.of(context)
                                  .translate('follow-your-reboot'),
                              style: kPageTitleStyle.copyWith(
                                  height: 1, fontSize: 28),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => NotesScreen()));
                          },
                          child: Icon(
                            Iconsax.book,
                            size: 32,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 12),
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
                                return Container(
                                  padding: EdgeInsets.all(20),
                                  width: MediaQuery.of(context).size.width,
                                  height:
                                      MediaQuery.of(context).size.height * 0.10,
                                  decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.2),
                                      borderRadius:
                                          BorderRadius.circular(12.5)),
                                  child: Center(
                                    child: Text(
                                      AppLocalizations.of(context)
                                          .translate("no-relapses"),
                                      style: kSubTitlesStyle.copyWith(
                                          color: Colors.green, fontSize: 18),
                                    ),
                                  ),
                                );
                              } else {
                                return Container(
                                  padding: EdgeInsets.all(20),
                                  width: MediaQuery.of(context).size.width,
                                  height: MediaQuery.of(context).size.height *
                                      0.225,
                                  decoration: BoxDecoration(
                                      color: accentColor.withOpacity(0.1),
                                      borderRadius:
                                          BorderRadius.circular(12.5)),
                                  //two lines of days
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      //first line of days
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: [
                                          //sunday
                                          Column(
                                            children: [
                                              Text(
                                                sunRelapses,
                                                style: kSubTitlesStyle.copyWith(
                                                    height: 1,
                                                    color: primaryColor),
                                              ),
                                              SizedBox(
                                                height: 8,
                                              ),
                                              Text(
                                                AppLocalizations.of(context)
                                                    .translate("sun"),
                                                style: kSubTitlesStyle.copyWith(
                                                    fontSize: 12,
                                                    color: primaryColor,
                                                    height: 1),
                                              ),
                                            ],
                                          ),
                                          Column(
                                            children: [
                                              Text(
                                                monRelapses,
                                                style: kSubTitlesStyle.copyWith(
                                                    height: 1,
                                                    color: primaryColor),
                                              ),
                                              SizedBox(
                                                height: 8,
                                              ),
                                              Text(
                                                AppLocalizations.of(context)
                                                    .translate("mon"),
                                                style: kSubTitlesStyle.copyWith(
                                                    fontSize: 12,
                                                    color: primaryColor,
                                                    height: 1),
                                              )
                                            ],
                                          ),
                                          Column(
                                            children: [
                                              Text(
                                                tueRelapses,
                                                style: kSubTitlesStyle.copyWith(
                                                    height: 1,
                                                    color: primaryColor),
                                              ),
                                              SizedBox(
                                                height: 8,
                                              ),
                                              Text(
                                                AppLocalizations.of(context)
                                                    .translate("tue"),
                                                style: kSubTitlesStyle.copyWith(
                                                    fontSize: 12,
                                                    color: primaryColor,
                                                    height: 1),
                                              )
                                            ],
                                          ),
                                          Column(
                                            children: [
                                              Text(
                                                wedRelapses,
                                                style: kSubTitlesStyle.copyWith(
                                                    height: 1,
                                                    color: primaryColor),
                                              ),
                                              SizedBox(
                                                height: 8,
                                              ),
                                              Text(
                                                AppLocalizations.of(context)
                                                    .translate("wed"),
                                                style: kSubTitlesStyle.copyWith(
                                                    fontSize: 12,
                                                    color: primaryColor,
                                                    height: 1),
                                              )
                                            ],
                                          ),
                                        ],
                                      ),
                                      //space
                                      SizedBox(
                                        height: 28,
                                      ),
                                      //second line of days
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: [
                                          Column(
                                            children: [
                                              Text(
                                                thuRelapses,
                                                style: kSubTitlesStyle.copyWith(
                                                    height: 1,
                                                    color: primaryColor),
                                              ),
                                              SizedBox(
                                                height: 8,
                                              ),
                                              Text(
                                                AppLocalizations.of(context)
                                                    .translate("thu"),
                                                style: kSubTitlesStyle.copyWith(
                                                    fontSize: 12,
                                                    color: primaryColor,
                                                    height: 1),
                                              )
                                            ],
                                          ),
                                          Column(
                                            children: [
                                              Text(
                                                friRelapses,
                                                style: kSubTitlesStyle.copyWith(
                                                    height: 1,
                                                    color: primaryColor),
                                              ),
                                              SizedBox(
                                                height: 8,
                                              ),
                                              Text(
                                                AppLocalizations.of(context)
                                                    .translate("fri"),
                                                style: kSubTitlesStyle.copyWith(
                                                    fontSize: 12,
                                                    color: primaryColor,
                                                    height: 1),
                                              )
                                            ],
                                          ),
                                          Column(
                                            children: [
                                              Text(
                                                satRelapses,
                                                style: kSubTitlesStyle.copyWith(
                                                    height: 1,
                                                    color: primaryColor),
                                              ),
                                              SizedBox(
                                                height: 8,
                                              ),
                                              Text(
                                                AppLocalizations.of(context)
                                                    .translate("sat"),
                                                style: kSubTitlesStyle.copyWith(
                                                    fontSize: 12,
                                                    color: primaryColor,
                                                    height: 1),
                                              )
                                            ],
                                          ),
                                        ],
                                      )
                                    ],
                                  ),
                                );
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
                            return Container(
                              padding: EdgeInsets.all(20),
                              width: MediaQuery.of(context).size.width,
                              height: MediaQuery.of(context).size.height * 0.10,
                              decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12.5)),
                              child: Center(
                                child: Text(
                                  AppLocalizations.of(context)
                                      .translate("no-relapses"),
                                  style: kSubTitlesStyle.copyWith(
                                      color: Colors.green, fontSize: 18),
                                ),
                              ),
                            );
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
              height: 20,
            ),
            Container(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      final DateTime now = DateTime.now();
                      final DateFormat formatter = DateFormat('yyyy-MM-dd');
                      final String today = formatter.format(now);
                      changeDateEvent(today);
                    },
                    child: Container(
                      width: (MediaQuery.of(context).size.width),
                      height: 50,
                      decoration: BoxDecoration(
                          color: primaryColor,
                          borderRadius: BorderRadius.circular(10)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            AppLocalizations.of(context)
                                .translate('daily-follow-up'),
                            style: kSubTitlesStyle.copyWith(
                                fontSize: 20,
                                color: Colors.white,
                                fontWeight: FontWeight.w400,
                                height: 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

//TODO - This needed to be refactored to not depend on the variable in the widget
  void dateChecker(DateTime date) {
    //get the range of the dates from the first recorded date until today
    final today = DateTime.now();

    //check if the date clicked is within the range, if yes pass it to the function, if not inform the user
    if (date.isAfter(resetDay != null ? resetDay : userFirstDayRecorded) &&
        date.isBefore(today)) {
      final dateStr = date.toString().substring(0, 11);
      changeDateEvent(dateStr);
    } else {
      outOfRangeAlert(context);
    }
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

  void performNewUserDialog() {
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
