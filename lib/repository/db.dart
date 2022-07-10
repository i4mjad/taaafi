import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:reboot_app_3/data/models/CalenderDay.dart';
import 'package:reboot_app_3/data/models/FollowUpData.dart';
import 'package:reboot_app_3/presentation/screens/follow_your_reboot/day_of_week_relapses/day_of_week_relapses_widget.dart';

class DB {
  final db = FirebaseFirestore.instance;
  final user = FirebaseAuth.instance.currentUser;
  String uid = FirebaseAuth.instance.currentUser.uid;

  Stream<DocumentSnapshot> initStream() {
    return db.collection("users").doc(uid).snapshots();
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

  Future<List<CalenderDay>> getCalenderData() async {
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
      return await today.difference(lastRelapseDay).inDays - 1;
    } else {
      return await today.difference(firstdate).inDays - 1;
    }
  }

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
      return await today.difference(lastNoPornDay).inDays - 1;
    } else {
      return await today.difference(firstdate).inDays - 1;
    }
  }

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
      return await today.difference(lastNoMastDay).inDays - 1;
    } else {
      return await today.difference(firstdate).inDays - 1;
    }
  }

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

  Future<DayOfWeekRelapses> getRelapsesByDayOfWeek() async {
    FollowUpData _followUpData = await getFollowUpData();
    List<dynamic> userRelapses = _followUpData.relapses;

    if (userRelapses.length > 0)
      return DayOfWeekRelapses(
        "0",
        "0",
        "0",
        "0",
        "0",
        "0",
        "0",
      );
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

    final satLength = (sat.length ?? 0).toString();
    final sunLength = (sun.length ?? 0).toString();
    final monLength = (mon.length ?? 0).toString();
    final tueLength = (tue.length ?? 0).toString();
    final wedLength = (wed.length ?? 0).toString();
    final thuLength = (thu.length ?? 0).toString();
    final friLength = (fri.length ?? 0).toString();

    final dayOfWeekRelapses = DayOfWeekRelapses(satLength, sunLength, monLength,
        tueLength, wedLength, thuLength, friLength);
    return dayOfWeekRelapses;
  }

  Future<String> getHighestStreak() async {
    FollowUpData _followUpData = await getFollowUpData();
    List<dynamic> _relapses = await _followUpData.relapses;

    if (_relapses == null) return "0";

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

  Future<String> getTotalDaysWithoutRelapse() async {
    FollowUpData _followUpData = await getFollowUpData();
    List<dynamic> _relapses = _followUpData.relapses;

    if (_followUpData.relapses == null) return "0";

    var _firstDate = await getStartingDate();

    var totalDays = DateTime.now().difference(_firstDate).inDays;

    var daysWithoutRelapses = totalDays - _relapses.length;

    return daysWithoutRelapses.toString();
  }

  Future<String> getTotalDaysFromBegining() async {
    var _firstDate = await getStartingDate();

    var totalDays = DateTime.now().difference(_firstDate).inDays;
    return totalDays.toString();
  }

  Future<String> getRelapsesCount() async {
    FollowUpData _followUpData = await getFollowUpData();
    List<dynamic> _relapses = _followUpData.relapses;

    return _relapses.length.toString();
  }

  Future<void> createNewData(DateTime selectedDate) {
    return db.collection("users").doc(user.uid).set({
      "uid": uid,
      "userFirstDate": selectedDate,
      "email": user.email,
      "userRelapses": [],
      "userMasturbatingWithoutWatching": [],
      "userWatchingWithoutMasturbating": [],
    });
  }

  void checkData() async {
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

  Stream<QuerySnapshot> getNotes() {
    return db.collection("users").doc(uid).collection("userNotes").snapshots();
  }

  Future<void> updateNote(String id, String title, String body) async {
    var data = {
      "title": title.toString(),
      "body": body.toString(),
    };
    print(id);
    return db
        .collection("users")
        .doc(uid)
        .collection("userNotes")
        .doc(id)
        .update(data);
  }

  Future<void> addNote(String title, String body) async {
    var data = {
      'title': title.toString(),
      "body": body.toString(),
      "timestamp": DateTime.now()
    };
    return db
        .collection("users")
        .doc(uid)
        .collection("userNotes")
        .doc()
        .set(data, SetOptions(merge: true));
  }

  Future<void> deleteNote(String id) async {
    return await db
        .collection("users")
        .doc(uid)
        .collection("userNotes")
        .doc(id)
        .delete();
  }
}

DB db = DB();
