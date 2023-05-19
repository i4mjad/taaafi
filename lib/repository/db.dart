import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:reboot_app_3/data/models/CalenderDay.dart';
import 'package:reboot_app_3/data/models/FollowUpData.dart';
import 'package:reboot_app_3/presentation/screens/follow_your_reboot/day_of_week_relapses/day_of_week_relapses_widget.dart';

class DB {
  final db = FirebaseFirestore.instance;
  final user = FirebaseAuth.instance.currentUser;
  String uid = FirebaseAuth.instance.currentUser.uid;

  Stream<DocumentSnapshot> initStream() {
    FirebaseCrashlytics.instance.setCustomKey("uid", uid);
    return db.collection("users").doc(uid).snapshots().asBroadcastStream();
  }

  Future<FollowUpData> getFollowUpData() async {
    await checkData();

    DocumentSnapshot snapshot = await db.collection("users").doc(uid).get();
    return FollowUpData.fromSnapshot(snapshot);
  }

  Future<DateTime> getResetDate() async {
    DocumentSnapshot snapshot = await db.collection("users").doc(uid).get();

    return DateTime.parse(
        await snapshot.get('resetedDate').toDate().toString());
  }

  Future<DateTime> getStartingDate() async {
    DocumentSnapshot snapshot = await db.collection("users").doc(uid).get();

    return DateTime.parse(
        await snapshot.get('userFirstDate').toDate().toString());
  }

//TODO #1: this method contains buisness logic and should be moved to the viewmodel
  Future<List<CalenderDay>> getCalenderData() async {
    //TODO: the two lines below are repository methods. Dont move them to viewmodel when you move the buisness logic. Instead, use the injected repository to get them
    FollowUpData _followUpDate = await getFollowUpData();
    DateTime _startingDate = await getStartingDate();
    var daysArray = <CalenderDay>[];
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

    List<DateTime> calculateDaysInterval(DateTime startDate, DateTime endDate) {
      List<DateTime> days = [];
      for (int i = 0; i <= endDate.difference(startDate).inDays; i++) {
        days.add(startDate.add(Duration(days: i)));
      }
      return days;
    }

    for (var date in calculateDaysInterval(_startingDate, today)) {
      final dateD = new DateTime(date.year, date.month, date.day);

      if (oldRelapses.contains(dateD)) {
        daysArray.add(new CalenderDay("Relapse", date, Colors.red));
      } else if (oldWatches.contains(dateD) && !oldRelapses.contains(dateD)) {
        daysArray.add(new CalenderDay("Watching Porn", date, Colors.purple));
      } else if (oldMasts.contains(dateD) && !oldRelapses.contains(dateD)) {
        daysArray.add(new CalenderDay("Masturbating", date, Colors.orange));
      } else {
        daysArray.add(new CalenderDay("Success", date, Colors.green));
      }
    }

    return await daysArray;
  }

//TODO #2: same as #1
  Future<int> getRelapseStreak() async {
    final firstdate = await getStartingDate();
    final followUpData = await getFollowUpData();
    List<dynamic> userRelapses = followUpData.relapses;
    var today = DateTime.now();
    if (userRelapses.length > 0) {
      userRelapses.sort((a, b) {
        return a.compareTo(b);
      });
      final lastRelapseDayStr = userRelapses[userRelapses.length - 1];
      final lastRelapseDay = DateTime.parse(lastRelapseDayStr);
      return await today.difference(lastRelapseDay).inDays;
    } else {
      return await today.difference(firstdate).inDays;
    }
  }

//TODO #3: same as #1
  Future<int> getNoPornStreak() async {
    //Get firstUserDate
    final firstdate = await getStartingDate();
    //Get userRelapses List
    final followUpData = await getFollowUpData();
    List<dynamic> userNoPornDays = followUpData
        .pornWithoutMasterbation; //if the userRelapses List contains no relapses
    var today = DateTime.now();
    //if the userRelapses List contains more than one relapse
    if (userNoPornDays.length > 0) {
      userNoPornDays.sort((a, b) {
        return a.compareTo(b);
      });
      final lastNoPornDayStr = userNoPornDays[userNoPornDays.length - 1];
      //make a date from the last relapse
      final lastNoPornDay = DateTime.parse(lastNoPornDayStr);
      //calculate the current streak by making time interval between today and the last
      return await today.difference(lastNoPornDay).inDays;
    } else {
      return await today.difference(firstdate).inDays;
    }
  }

//TODO #4: same as #1
  Future<int> getNoMastsStreak() async {
    //Get firstUserDate
    final firstdate = await getStartingDate();
    //Get userRelapses List
    final followUpData = await getFollowUpData();
    List<dynamic> userNoMastDays = followUpData
        .masterbationWithoutPorn; //if the userRelapses List contains no relapses
    var today = DateTime.now();
    //if the userRelapses List contains more than one relapse
    if (userNoMastDays.length > 0) {
      userNoMastDays.sort((a, b) {
        return a.compareTo(b);
      });
      final lastNoMastDayStr = userNoMastDays[userNoMastDays.length - 1];
      //make a date from the last relapse
      final lastNoMastDay = DateTime.parse(lastNoMastDayStr);
      //calculate the current streak by making time interval between today and the last
      return await today.difference(lastNoMastDay).inDays;
    } else {
      return await today.difference(firstdate).inDays;
    }
  }

//TODO #5: this method when moved to the repository should ONLY add to the database. The buisness logic should be in the viewmodel layer
  addRelapse(String date) async {
    FollowUpData _followUpData = await getFollowUpData();
    List<dynamic> _watchOnly = _followUpData.pornWithoutMasterbation;
    List<dynamic> _mastOnly = _followUpData.masterbationWithoutPorn;
    List<dynamic> _relapses = _followUpData.relapses;

    if (_watchOnly.contains(date)) return;
    if (_mastOnly.contains(date)) return;
    if (_relapses.contains(date)) return;

    _watchOnly.add(date);
    _mastOnly.add(date);
    _relapses.add(date);
    db.collection("users").doc(user.uid).update({
      "userRelapses": _relapses,
      "userMasturbatingWithoutWatching": _mastOnly,
      "userWatchingWithoutMasturbating": _watchOnly,
    });
  }

//TODO #6: same as #5
  addSuccess(String date) async {
    FollowUpData _followUpData = await getFollowUpData();
    List<dynamic> _watchOnly = _followUpData.pornWithoutMasterbation;
    List<dynamic> _mastOnly = _followUpData.masterbationWithoutPorn;
    List<dynamic> _relapses = _followUpData.relapses;

    if (_watchOnly.contains(date)) {
      _watchOnly.remove(date);
    }
    if (_mastOnly.contains(date)) {
      _mastOnly.remove(date);
    }
    if (_relapses.contains(date)) {
      _relapses.remove(date);
    }

    db.collection("users").doc(user.uid).update({
      "userRelapses": _relapses,
      "userMasturbatingWithoutWatching": _mastOnly,
      "userWatchingWithoutMasturbating": _watchOnly,
    });
  }

//TODO #7: same as #5
  addWatchOnly(String date) async {
    FollowUpData _followUpData = await getFollowUpData();
    List<dynamic> _days = _followUpData.pornWithoutMasterbation;

    if (_days.contains(date)) return;
    _days.add(date);

    db
        .collection("users")
        .doc(user.uid)
        .update({"userWatchingWithoutMasturbating": _days});
  }

//TODO #8: same as #5
  addMastOnly(String date) async {
    FollowUpData _followUpData = await getFollowUpData();
    List<dynamic> _days = _followUpData.masterbationWithoutPorn;

    if (_days.contains(date)) return;
    _days.add(date);
    db
        .collection("users")
        .doc(user.uid)
        .update({"userMasturbatingWithoutWatching": _days});
  }

//TODO #9: same as #5
  Future<DayOfWeekRelapses> getRelapsesByDayOfWeek() async {
    var followUpData = await getFollowUpData();
    var userRelapses = followUpData.relapses;
    int totalRelapses = userRelapses.length;
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

      if (dayOfWeek == 1) {
        sun.add(date);
      } else if (dayOfWeek == 2) {
        mon.add(date);
      } else if (dayOfWeek == 3) {
        tue.add(date);
      } else if (dayOfWeek == 4) {
        wed.add(date);
      } else if (dayOfWeek == 5) {
        thu.add(date);
      } else if (dayOfWeek == 6) {
        fri.add(date);
      } else if (dayOfWeek == 7) {
        sat.add(date);
      }
    }

    final satLength = (sat.length / totalRelapses) ?? 0;
    final monLength = (mon.length / totalRelapses) ?? 0;
    final sunLength = (sun.length / totalRelapses) ?? 0;
    final tueLength = (tue.length / totalRelapses) ?? 0;
    final wedLength = (wed.length / totalRelapses) ?? 0;
    final thuLength = (thu.length / totalRelapses) ?? 0;
    final friLength = (fri.length / totalRelapses) ?? 0;

    final dayOfWeekRelapses = DayOfWeekRelapses(
        new DayOfWeekRelapsesDetails(satLength, sat.length),
        new DayOfWeekRelapsesDetails(sunLength, sun.length),
        new DayOfWeekRelapsesDetails(monLength, mon.length),
        new DayOfWeekRelapsesDetails(tueLength, tue.length),
        new DayOfWeekRelapsesDetails(wedLength, wed.length),
        new DayOfWeekRelapsesDetails(thuLength, thu.length),
        new DayOfWeekRelapsesDetails(friLength, fri.length),
        totalRelapses.toString());
    return dayOfWeekRelapses;
  }

//TODO #10: same as #5
  Future<String> getHighestStreak() async {
    FollowUpData _followUpData = await getFollowUpData();
    List<dynamic> _relapses = await _followUpData.relapses;

    if (_relapses == null || _relapses.length == 0) return "0";

    final DateTime today = DateTime.now();
    final DateTime todayE = DateTime(today.year, today.month, today.day);

    var relapsesInDate = [];

    if (_relapses.length > 0) {
      relapsesInDate.clear();
      for (var i in _relapses) {
        final date = DateTime.parse(i);
        relapsesInDate.add(date);
      }
    }

    relapsesInDate.add(todayE);
    final userFirstDate = await getStartingDate();

    List<int> differences = [];

    relapsesInDate.sort((a, b) {
      return a.compareTo(b);
    });

    if (relapsesInDate.length > 0) {
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

    return differences.reduce((max)).toString();
  }

//TODO #11: same as #5
  Future<String> getTotalDaysWithoutRelapse() async {
    FollowUpData _followUpData = await getFollowUpData();
    List<dynamic> _relapses = _followUpData.relapses;

    if (_followUpData.relapses == null) return "0";

    var _firstDate = await getStartingDate();

    var totalDays = DateTime.now().difference(_firstDate).inDays;

    var daysWithoutRelapses = totalDays - _relapses.length;

    return daysWithoutRelapses.toString();
  }

//TODO #12: same as #5
  Future<String> getTotalDaysFromBegining() async {
    var _firstDate = await getStartingDate();

    var totalDays = DateTime.now().difference(_firstDate).inDays;
    return totalDays.toString();
  }

//TODO #13: same as #5
  Future<String> getRelapsesCount() async {
    FollowUpData _followUpData = await getFollowUpData();
    List<dynamic> _relapses = _followUpData.relapses;

    return _relapses.length.toString();
  }

  void checkData() async {
    //TODO: this method need to be tracked to see if it is still used, consider checking the Firebase Analytics custom events to achieve this.
    return await db.collection("users").doc(uid).get().then((value) async {
      Map<String, dynamic> data = value.data();
      if (!(await data.containsKey("userRelapses"))) {
        await db.collection("users").doc(user.uid).set({
          "userRelapses": [],
        }, SetOptions(merge: true));
      }
      if (!(await data.containsKey("userWatchingWithoutMasturbating"))) {
        await db.collection("users").doc(user.uid).set({
          "userWatchingWithoutMasturbating": [],
        }, SetOptions(merge: true));
      }
      if (!(await data.containsKey("userMasturbatingWithoutWatching"))) {
        await db.collection("users").doc(user.uid).set({
          "userMasturbatingWithoutWatching": [],
        }, SetOptions(merge: true));
      }
      if (!(await data.containsKey("userFirstDate"))) {
        await migerateToUserFirstDate();
      }
    });
  }

  void migerateToUserFirstDate() async {
    //TODO: this method need to be tracked to see if it is still used by any user,
    // consider checking the Firebase Analytics custom events to achieve this.
    var _db = db.collection("users").doc(user.uid);

    _db.get().then((value) async {
      Map<String, dynamic> data = value.data();
      if (await data.containsKey("userFirstDate") == false) {
        var userRigDate = user.metadata.creationTime;
        int userFirstStreak = await data["userPreviousStreak"];

        DateTime userResetDate = data["resetedDate"] != null
            ? await DateTime.parse(data["resetedDate"].toDate().toString())
            : null;
        DateTime parseFirstDate = await DateTime(userRigDate.year,
            userRigDate.month, userRigDate.day - userFirstStreak);
        DateTime userFirstDate =
            await userResetDate != null ? userResetDate : parseFirstDate;

        var firstDate = {"userFirstDate": userFirstDate};
        await db
            .collection("users")
            .doc(user.uid)
            .set(firstDate, SetOptions(merge: true))
            .onError((error, stackTrace) => print(error));
      }
    });
  }

  Future<String> getRelapsesCountInLast30Days() async {
    await checkData();
    int _count = 0;
    FollowUpData _followUpDate = await getFollowUpData();
    List relapses = _followUpDate.relapses;
    DateTime today = DateTime.now();
    DateTime _dateBefore30Days = DateTime.now().subtract(Duration(days: 28));

    List<String> _last30Days() {
      List<String> days = [];

      for (int i = 0; i <= today.difference(_dateBefore30Days).inDays; i++) {
        DateTime d = _dateBefore30Days.add(Duration(days: i));
        days.add(
            new DateTime(d.year, d.month, d.day).toString().substring(0, 10));
      }
      return days;
    }

    for (var date in relapses) {
      if (_last30Days().contains(date.toString().substring(0, 10))) {
        _count += 1;
      }
    }
    return await _count.toString();
  }
}

DB db = DB();
