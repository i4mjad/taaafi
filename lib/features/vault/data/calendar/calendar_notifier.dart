import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_app_3/features/vault/application/calendar_service.dart';
import 'package:reboot_app_3/features/vault/data/calendar/calendar_repository.dart';
import 'package:reboot_app_3/features/shared/models/follow_up.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'calendar_notifier.g.dart';

@riverpod
Stream<List<FollowUpModel>> calendarStream(Ref ref) {
  final service = ref.read(calendarServiceProvider);
  return service.followUpsStream();
}

/// A provider for the [CalendarService].
@Riverpod(keepAlive: true)
CalendarService calendarService(Ref ref) {
  final firestore = FirebaseFirestore.instance;
  final repository = CalendarRepository(firestore);
  return CalendarService(repository);
}

@Riverpod(keepAlive: true)
class CalendarNotifier extends _$CalendarNotifier {
  CalendarService get service => ref.read(calendarServiceProvider);

  @override
  FutureOr<List<FollowUpModel>> build() async {
    return await service.getFollowUps();
  }

  Future<void> fetchFollowUpsForDates(List<DateTime> dates) async {
    state = const AsyncValue.loading();
    try {
      final followUps = await service.fetchFollowUpsForDates(dates);
      state = AsyncValue.data(followUps);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<List<FollowUpModel>> fetchFollowUpsForMonth(DateTime month) async {
    final startOfMonth = DateTime(month.year, month.month, 1);
    final endOfMonth = DateTime(month.year, month.month + 1, 0);
    return await service.fetchFollowUpsForDateRange(startOfMonth, endOfMonth);
  }

  Future<DateTime> getUserFirstDate() async {
    return await service.getUserFirstDate();
  }
}
