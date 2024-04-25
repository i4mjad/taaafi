import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_app_3/data/models/CalenderDay.dart';
import 'package:reboot_app_3/data/models/FollowUpData.dart';
import 'package:reboot_app_3/di/container.dart';
import 'package:reboot_app_3/presentation/screens/follow_your_reboot/day_of_week_relapses/day_of_week_relapses_widget.dart';
import 'package:reboot_app_3/repository/follow_up_data_repository.dart';
import 'package:reboot_app_3/shared/constants/customer_io_attributes_const.dart';
import 'package:reboot_app_3/shared/services/promize_service.dart';

class FollowUpViewModel extends StateNotifier<FollowUpData> {
  final IFollowUpDataRepository _followUpRepository;
  final ICustomerIOService _promizeService = getIt<ICustomerIOService>();

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

  Future<void> addRelapse(String date) async {
    FollowUpData _followUpData = await _followUpRepository.getFollowUpData();
    List<String> _watchOnly = _followUpData.pornWithoutMasterbation;
    List<String> _mastOnly = _followUpData.masterbationWithoutPorn;
    List<String> _relapses = _followUpData.relapses;

    if (_watchOnly.contains(date)) return;
    if (_mastOnly.contains(date)) return;
    if (_relapses.contains(date)) return;

    _watchOnly.add(date);
    _mastOnly.add(date);
    _relapses.add(date);
    var data = {
      "userRelapses": _relapses,
      "userMasturbatingWithoutWatching": _mastOnly,
      "userWatchingWithoutMasturbating": _watchOnly,
    };

    _promizeService.checkIn(
      EventsNames.Relapse,
      DateTime.now(),
      relapsesStreak: await getRelapseStreak(),
      mastStreak: await getNoMastsStreak(),
      pornStreak: await getNoPornStreak(),
    );

    _promizeService.updateUser({
      ProfileAttributesConstants.TotalDays: await getTotalDaysFromBegining(),
      ProfileAttributesConstants.NoRelapseDays:
          await getTotalDaysWithoutRelapse(),
      ProfileAttributesConstants.RelapsesCount:
          int.parse(await getRelapsesCount()) + 1,
      ProfileAttributesConstants.HighestStreak: await getHighestStreak(),
    });
    await _followUpRepository.updateFollowUpData(data);
  }

  Future<void> addSuccess(String date) async {
    FollowUpData _followUpData = await _followUpRepository.getFollowUpData();
    List<String> _watchOnly = _followUpData.pornWithoutMasterbation;
    List<String> _mastOnly = _followUpData.masterbationWithoutPorn;
    List<String> _relapses = _followUpData.relapses;

    if (_watchOnly.contains(date)) {
      _watchOnly.remove(date);
    }
    if (_mastOnly.contains(date)) {
      _mastOnly.remove(date);
    }
    if (_relapses.contains(date)) {
      _relapses.remove(date);
    }

    var data = {
      "userRelapses": _relapses,
      "userMasturbatingWithoutWatching": _mastOnly,
      "userWatchingWithoutMasturbating": _watchOnly,
    };
    _promizeService.checkIn(
      EventsNames.Success,
      DateTime.now(),
    );

    _promizeService.updateUser({
      ProfileAttributesConstants.TotalDays: await getTotalDaysFromBegining(),
      ProfileAttributesConstants.NoRelapseDays:
          await getTotalDaysWithoutRelapse(),
      ProfileAttributesConstants.RelapsesCount:
          int.parse(await getRelapsesCount()),
      ProfileAttributesConstants.HighestStreak: await getHighestStreak(),
    });
    await _followUpRepository.updateFollowUpData(data);
  }

  Future<void> addWatchOnly(String date) async {
    FollowUpData _followUpData = await _followUpRepository.getFollowUpData();
    List<String> _days = _followUpData.pornWithoutMasterbation;

    if (_days.contains(date)) return;
    _days.add(date);
    var data = {"userWatchingWithoutMasturbating": _days};
    _promizeService.checkIn(
      EventsNames.PornWithoutMast,
      DateTime.now(),
      pornStreak: await getNoPornStreak(),
    );

    _promizeService.updateUser({
      ProfileAttributesConstants.TotalDays: await getTotalDaysFromBegining(),
      ProfileAttributesConstants.NoRelapseDays:
          await getTotalDaysWithoutRelapse(),
      ProfileAttributesConstants.RelapsesCount:
          int.parse(await getRelapsesCount()),
      ProfileAttributesConstants.HighestStreak: await getHighestStreak(),
    });
    await _followUpRepository.updateFollowUpData(data);
  }

  Future<void> addMastOnly(String date) async {
    FollowUpData _followUpData = await _followUpRepository.getFollowUpData();
    List<String> _days = _followUpData.masterbationWithoutPorn;

    if (_days.contains(date)) return;
    _days.add(date);

    var data = {"userMasturbatingWithoutWatching": _days};

    _promizeService.checkIn(
      EventsNames.PornWithoutMast,
      DateTime.now(),
      pornStreak: await getNoPornStreak(),
    );

    await _followUpRepository.updateFollowUpData(data);
  }

  Future<DayOfWeekRelapses> getRelapsesByDayOfWeek() async {
    var followUpData = await _followUpRepository.getFollowUpData();
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

    var satLength = (sat.length / totalRelapses);
    var monLength = (mon.length / totalRelapses);
    var sunLength = (sun.length / totalRelapses);
    var tueLength = (tue.length / totalRelapses);
    var wedLength = (wed.length / totalRelapses);
    var thuLength = (thu.length / totalRelapses);
    var friLength = (fri.length / totalRelapses);

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

  Future<String> getHighestStreak() async {
    FollowUpData _followUpData = await _followUpRepository.getFollowUpData();
    List<String> _relapses = await _followUpData.relapses;

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
    final userFirstDate = await _followUpRepository.getStartingDate();

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
    FollowUpData _followUpData = await _followUpRepository.getFollowUpData();
    List<String> _relapses = _followUpData.relapses;

    if (_followUpData.relapses == null) return "0";

    var _firstDate = await _followUpRepository.getStartingDate();

    var totalDays = DateTime.now().difference(_firstDate).inDays;

    var daysWithoutRelapses = totalDays - _relapses.length;

    return daysWithoutRelapses.toString();
  }

  Future<String> getTotalDaysFromBegining() async {
    var _firstDate = await _followUpRepository.getStartingDate();

    var totalDays = DateTime.now().difference(_firstDate).inDays;
    return totalDays.toString();
  }

  Future<String> getRelapsesCount() async {
    FollowUpData _followUpData = await _followUpRepository.getFollowUpData();
    List<String> _relapses = _followUpData.relapses;

    return _relapses.length.toString();
  }

  Future<String> getRelapsesCountInLast30Days() async {
    int _count = 0;
    FollowUpData _followUpDate = await _followUpRepository.getFollowUpData();
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

  Future<DateTime> getFirstDate() async {
    return await _followUpRepository.getStartingDate();
  }

  Future<void> registerPromizeUser(
      String gender, String locale, DateTime dob) async {
    _promizeService.createUser(gender, locale, dob);
  }
}
