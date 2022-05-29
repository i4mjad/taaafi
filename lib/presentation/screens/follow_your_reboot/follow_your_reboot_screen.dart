import 'dart:core';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:reboot_app_3/Model/Relapse.dart';
import 'package:reboot_app_3/bloc_provider.dart';
import 'package:reboot_app_3/data/models/user_profile.dart';
import 'package:reboot_app_3/presentation/Screens/auth/login_screen.dart';
import 'package:reboot_app_3/presentation/blocs/follow_your_reboot_bloc.dart';
import 'package:reboot_app_3/presentation/screens/follow_your_reboot/calender/calender_widget.dart';
import 'package:reboot_app_3/presentation/screens/follow_your_reboot/follow_up_streaks/follow_up_streak.dart';
import 'package:reboot_app_3/shared/constants/constants.dart';
import 'package:reboot_app_3/shared/constants/textstyles_constants.dart';
import 'package:reboot_app_3/shared/localization/localization.dart';
import 'package:reboot_app_3/shared/localization/localization_services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
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
  FollowYourRebootScreenState createState() => FollowYourRebootScreenState();
}

class FollowYourRebootScreenState extends State<FollowYourRebootScreen>
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
          //newUserDialog();
        } else {
          //TODO - TPUR02-02
          if (snapshot.exists == false) {
            // newUserDialog();
          }
        }
      }
    });
  }

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

  var days = <Day>[];

  void getCalenderData() async {
    final db = FirebaseFirestore.instance;
    final user = FirebaseAuth.instance.currentUser;
    final uid = FirebaseAuth.instance.currentUser.uid;

    db.collection("users").doc(uid).snapshots().listen((snapshot) async {
      FollowUpData _followUpDate = FollowUpData.fromSnapshot(snapshot);
      DateTime _startingDate = DateTime.parse(
          await snapshot.get('userFirstDate').toDate().toString());

      var daysArray = <Day>[];
      var oldRelapses = <DateTime>[];
      var oldWatches = <DateTime>[];
      var oldMasts = <DateTime>[];

      final today = DateTime.now();

      oldRelapses.clear();
      for (var strDate in _followUpDate.relapses) {
        final date = DateTime.parse(strDate);
        oldRelapses.add(date);
      }
      oldWatches.clear();
      for (var strDate in _followUpDate.pornWithoutMasterbation) {
        final date = DateTime.parse(strDate);
        oldWatches.add(date);
      }
      oldMasts.clear();
      for (var strDate in _followUpDate.masterbationWithoutPorn) {
        final date = DateTime.parse(strDate);
        oldMasts.add(date);
      }

      List<DateTime> calculateDaysInterval(
          DateTime startDate, DateTime endDate) {
        List<DateTime> days = [];
        for (int i = 0; i <= endDate.difference(startDate).inDays; i++) {
          days.add(startDate.add(Duration(days: i)));
        }
        return days;
      }

      for (var date in calculateDaysInterval(_startingDate, today)) {
        final dateD = new DateTime(date.year, date.month, date.day);

        if (oldRelapses.contains(dateD)) {
          daysArray.add(new Day("Relapse", date, Colors.red));
        } else if (oldWatches.contains(dateD) && !oldRelapses.contains(dateD)) {
          daysArray.add(new Day("Watching Porn", date, Colors.purple));
        } else if (oldMasts.contains(dateD) && !oldRelapses.contains(dateD)) {
          daysArray.add(new Day("Masturbating", date, Colors.orange));
        } else {
          daysArray.add(new Day("Success", date, Colors.green));
        }
      }

      setState(() {
        days = daysArray;
      });
    });
  }

  void migerateToUserFirstDate() async {
    var _db = database.collection("users").doc(user.uid);

    return _db.get().then((value) async {
      if (await value.data().containsKey("userFirstDate") == false) {
        var userRigDate = user.metadata.creationTime;
        int userFirstStreak = await value.data()["userPreviousStreak"];

        DateTime userResetDate = value.data()["resetedDate"] != null
            ? await DateTime.parse(
                value.data()["resetedDate"].toDate().toString())
            : null;
        DateTime parseFirstDate = await DateTime(userRigDate.year,
            userRigDate.month, userRigDate.day - userFirstStreak);
        DateTime userFirstDate =
            await userResetDate != null ? userResetDate : parseFirstDate;

        var firstDate = {"userFirstDate": userFirstDate};
        await database
            .collection("users")
            .doc(user.uid)
            .set(firstDate, SetOptions(merge: true))
            .onError((error, stackTrace) => print(error))
            .then((value) {
          setState(() {});
        });
      }
    });
  }

  @override
  void initState() {
    migerateToUserFirstDate();
    getCalenderData();
    super.initState();
    loadUserRelapces();
    loadUserWatchesOnly();
    loadUserMastsOnly();
    LocaleService.getSelectedLocale().then((value) {
      setState(() {
        lang = value;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final bloc = CustomBlocProvider.of<FollowYourRebootBloc>(context);
    return Scaffold(
        backgroundColor: seconderyColor.withOpacity(0.2),
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
                FollowUpStreaks(),
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
                              height: MediaQuery.of(context).size.height * 0.45,
                              decoration: BoxDecoration(
                                  color: mainGrayColor,
                                  borderRadius: BorderRadius.circular(15)),
                              child: SfCalendar(
                                onTap: (CalendarTapDetails details) async {
                                  DateTime date = details.date;
                                  DateTime firstDate =
                                      await bloc.getFirstDate();

                                  dateChecker(firstDate, date, context, bloc);
                                },
                                view: CalendarView.month,
                                headerStyle: CalendarHeaderStyle(
                                    textAlign: TextAlign.center,
                                    backgroundColor: mainYellowColor,
                                    textStyle: kSubTitlesStyle),
                                dataSource: CalenderDataSource(days),
                                monthViewSettings: MonthViewSettings(
                                  //showAgenda: true,
                                  agendaStyle: AgendaStyle(),
                                  appointmentDisplayMode:
                                      MonthAppointmentDisplayMode.indicator,
                                ),
                                allowAppointmentResize: true,
                              )),
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

  changeDateEvent(
      String date, BuildContext context, FollowYourRebootBloc bloc) async {
    final trimedDate = date.trim();
    showModalBottomSheet(
        context: context,
        builder: (context) {
          return Padding(
            padding: EdgeInsets.only(left: 20.0, right: 20, top: 8, bottom: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
                        Iconsax.close_circle,
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
                      AppLocalizations.of(context).translate("how-is-this-day"),
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
                        bloc.addRelapse(date);
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
                        bloc.addSuccess(date);

                        Navigator.pop(context);
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
                        bloc.addWatchOnly(date);

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
                        bloc.addMastOnly(date);

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

  dateChecker(DateTime firstDate, DateTime date, BuildContext context,
      FollowYourRebootBloc bloc) {
    if (dayWithinRange(firstDate, date)) {
      final dateStr = date.toString().substring(0, 10);
      changeDateEvent(dateStr, context, bloc);
    } else {
      outOfRangeAlert(context);
    }
  }

  void outOfRangeAlert(BuildContext context) {
    showModalBottomSheet(
        context: context,
        builder: (context) {
          return Padding(
            padding: EdgeInsets.fromLTRB(0, 8, 0, 0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: 5,
                      width: MediaQuery.of(context).size.width * 0.1,
                      decoration: BoxDecoration(
                          color: Colors.black12,
                          borderRadius: BorderRadius.circular(30)),
                    )
                  ],
                ),
                SizedBox(
                  height: 12,
                ),
                CircleAvatar(
                  backgroundColor: Colors.red.withOpacity(0.2),
                  child: Icon(
                    Iconsax.warning_2,
                    color: Colors.red,
                  ),
                ),
                SizedBox(
                  height: 4,
                ),
                Text(
                  AppLocalizations.of(context).translate("out-of-range"),
                  style:
                      kPageTitleStyle.copyWith(color: Colors.red, fontSize: 24),
                ),
                SizedBox(
                  height: 8,
                ),
                Text(
                  AppLocalizations.of(context).translate('out-of-range-p'),
                  style: kSubTitlesStyle.copyWith(
                      color: Colors.black.withOpacity(0.7),
                      fontWeight: FontWeight.normal,
                      fontSize: 18),
                ),
                SizedBox(
                  height: 30,
                )
              ],
            ),
          );
        });
  }

  bool dayWithinRange(DateTime firstDate, DateTime date) {
    final today = DateTime.now();
    return date.isAfter(firstDate) && date.isBefore(today);
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
      return CustomBlocProvider(
          bloc: FollowYourRebootBloc(), child: FollowYourRebootScreen());
    } else {
      return LoginScreen();
    }
  }
}
