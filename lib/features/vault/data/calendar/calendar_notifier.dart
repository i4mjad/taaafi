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

  // Cache for loaded months to avoid refetching
  final Map<String, List<FollowUpModel>> _monthCache = {};

  // Track if we're currently loading to avoid showing loading for month changes
  bool _isInitialLoad = true;

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

  Future<void> fetchFollowUpsForMonth(DateTime month) async {
    final monthKey = '${month.year}-${month.month}';

    // Check cache first
    if (_monthCache.containsKey(monthKey)) {
      // Update state without loading indicator for cached data
      final currentData = state.value ?? [];
      final cachedData = _monthCache[monthKey]!;

      // Merge cached data with existing data (remove duplicates)
      final allFollowUps = <FollowUpModel>[...currentData];
      for (final followUp in cachedData) {
        if (!allFollowUps.any((existing) => existing.id == followUp.id)) {
          allFollowUps.add(followUp);
        }
      }

      state = AsyncValue.data(allFollowUps);
      return;
    }

    // Only show loading state for initial load or if no data exists
    if (_isInitialLoad || state.value == null) {
      state = const AsyncValue.loading();
    }

    try {
      final startOfMonth = DateTime(month.year, month.month, 1);
      final endOfMonth = DateTime(month.year, month.month + 1, 0);
      final followUps =
          await service.fetchFollowUpsForDateRange(startOfMonth, endOfMonth);

      // Cache the month data
      _monthCache[monthKey] = followUps;

      // Merge with existing data instead of replacing
      final currentData = state.value ?? [];
      final allFollowUps = <FollowUpModel>[...currentData];

      // Add new follow-ups that don't already exist
      for (final followUp in followUps) {
        if (!allFollowUps.any((existing) => existing.id == followUp.id)) {
          allFollowUps.add(followUp);
        }
      }

      state = AsyncValue.data(allFollowUps);
      _isInitialLoad = false;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<DateTime> getUserFirstDate() async {
    return await service.getUserFirstDate();
  }

  // Method to clear cache if needed (e.g., when data changes)
  void clearCache() {
    _monthCache.clear();
  }
}
