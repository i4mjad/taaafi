import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_app_3/data/models/CalenderDay.dart';
import 'package:reboot_app_3/data/models/FollowUpData.dart';
import 'package:reboot_app_3/di/container.dart';
import 'package:reboot_app_3/repository/follow_up_data_repository.dart';

class FollowUpViewModel extends StateNotifier<FollowUpData> {
  final IFollowUpDataRepository _followUpRepository;

  FollowUpViewModel()
      : _followUpRepository = getIt<IFollowUpDataRepository>(),
        super(FollowUpData.Missing) {
    _followUpRepository.getFollowUpDataStream().listen((followUpData) {
      state = followUpData;
    });
  }

  Future<List<CalenderDay>> getCalenderData() async {
    FollowUpData _followUpDate = await _followUpRepository.getFollowUpData();
    DateTime _startingDate = await _followUpRepository.getStartingDate();
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
    final firstdate = await _followUpRepository.getStartingDate();
    final followUpData = await _followUpRepository.getFollowUpData();
    List<String> userRelapses = followUpData.relapses;
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

  Future<int> getNoPornStreak() async {
    final firstdate = await _followUpRepository.getStartingDate();
    final followUpData = await _followUpRepository.getFollowUpData();
    List<String> userNoPornDays = followUpData.pornWithoutMasterbation;
    var today = DateTime.now();

    if (userNoPornDays.length > 0) {
      userNoPornDays.sort((a, b) {
        return a.compareTo(b);
      });
      final lastNoPornDayStr = userNoPornDays[userNoPornDays.length - 1];
      final lastNoPornDay = DateTime.parse(lastNoPornDayStr);
      return await today.difference(lastNoPornDay).inDays;
    } else {
      return await today.difference(firstdate).inDays;
    }
  }

  Future<int> getNoMastsStreak() async {
    final firstdate = await _followUpRepository.getStartingDate();
    final followUpData = await _followUpRepository.getFollowUpData();
    List<String> userNoMastDays = followUpData.masterbationWithoutPorn;
    var today = DateTime.now();
    if (userNoMastDays.length > 0) {
      userNoMastDays.sort((a, b) {
        return a.compareTo(b);
      });
      final lastNoMastDayStr = userNoMastDays[userNoMastDays.length - 1];
      final lastNoMastDay = DateTime.parse(lastNoMastDayStr);
      return await today.difference(lastNoMastDay).inDays;
    } else {
      return await today.difference(firstdate).inDays;
    }
  }
}
