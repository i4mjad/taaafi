import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:reboot_app_3/Model/Relapse.dart';
import 'package:reboot_app_3/data/models/user_profile.dart';

class DB {
  final db = FirebaseFirestore.instance;
  final user = FirebaseAuth.instance.currentUser;
  final uid = FirebaseAuth.instance.currentUser.uid;

  Stream<DocumentSnapshot> initStream() {
    return db.collection("users").doc(uid).snapshots();
  }

  Future<FollowUpData> getFollowUpData() async {
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
        await snapshot.get('startingDate').toDate().toString());
  }

  Future<List<Day>> getCalenderData() async {
    FollowUpData _followUpDate = await getFollowUpData();
    DateTime _startingDate = await getStartingDate();
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
        daysArray.add(new Day("Relapse", date, Colors.red));
      } else if (oldWatches.contains(dateD) && !oldRelapses.contains(dateD)) {
        daysArray.add(new Day("Watching Porn", date, Colors.purple));
      } else if (oldMasts.contains(dateD) && !oldRelapses.contains(dateD)) {
        daysArray.add(new Day("Masturbating", date, Colors.orange));
      } else {
        daysArray.add(new Day("Success", date, Colors.green));
      }
    }

    return await daysArray;
  }
}

DB db = DB();
