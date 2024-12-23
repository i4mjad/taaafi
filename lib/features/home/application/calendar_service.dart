import 'package:reboot_app_3/features/home/data/repos/calendar_repository.dart';
import 'package:reboot_app_3/features/shared/models/follow_up.dart';

/// A service that contains business logic or computation related to calendar followUps.
class CalendarService {
  final CalendarRepository _repository;

  CalendarService(this._repository);

  Future<List<FollowUpModel>> fetchFollowUpsForDateRange(
      DateTime start, DateTime end) async {
    return await _repository.readFollowUpsForDateRange(start, end);
  }

  Future<List<FollowUpModel>> fetchFollowUpsForDates(
      List<DateTime> dates) async {
    return await _repository.readFollowUpsForDates(dates);
  }

  Future<List<FollowUpModel>> fetchFollowUpsForMonth(
      int year, int month) async {
    DateTime start = DateTime(year, month, 1);
    DateTime end = DateTime(year, month + 1, 0);
    return await _repository.readFollowUpsForDateRange(start, end);
  }

  Future<DateTime> getUserFirstDate() async {
    return await _repository.getUserFirstDate();
  }
}
