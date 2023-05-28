import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:reboot_app_3/bloc_provider.dart';
import 'package:reboot_app_3/data/models/FollowUpData.dart';
import 'package:reboot_app_3/presentation/screens/follow_your_reboot/day_of_week_relapses/day_of_week_relapses_widget.dart';
import 'package:reboot_app_3/repository/db.dart';
import 'package:rxdart/subjects.dart';

class FollowYourRebootBloc implements CustomBlocBase {
  FollowYourRebootBloc() {
    db.initStream().listen((data) => _inFirestore.add(data));
  }

  final _firestoreController = BehaviorSubject<DocumentSnapshot>();
  Stream<DocumentSnapshot> get outFirestore => _firestoreController.stream;
  Sink<DocumentSnapshot> get _inFirestore => _firestoreController.sink;

  readFollowUpData() async {
    FollowUpData data = await db.getFollowUpData();
    return data;
  }

  Future<int> getNoPornStreak() async {
    return await db.getNoPornStreak();
  }

  Future<int> getNoMastsStreak() async {
    return await db.getNoMastsStreak();
  }

  Future<DateTime> getFirstDate() async {
    return await db.getStartingDate();
  }

  void addRelapse(String date) async {
    await db.addRelapse(date);
  }

  void addSuccess(String date) async {
    await db.addSuccess(date);
  }

  void addWatchOnly(String date) async {
    await db.addWatchOnly(date);
  }

  void addMastOnly(String date) async {
    await db.addMastOnly(date);
  }

  Future<DayOfWeekRelapses> getRelapsesByDayOfWeek() async {
    return await db.getRelapsesByDayOfWeek();
  }

  Future<String> getHighestStreak() async {
    return await db.getHighestStreak();
  }

  Future<String> getTotalDaysWithoutRelapse() async {
    return await db.getTotalDaysWithoutRelapse();
  }

  Future<String> getTotalDaysFromBegining() async {
    return await db.getTotalDaysFromBegining();
  }

  Future<String> getRelapsesCount() async {
    return await db.getRelapsesCount();
  }

  Future<String> getRelapsesCountInLast30Days() async {
    return await db.getRelapsesCountInLast30Days();
  }

  @override
  void dispose() async {
    return _firestoreController.close();
  }

  Stream<DocumentSnapshot> streamUserDoc() {
    return db.initStream();
  }
}
