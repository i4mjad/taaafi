// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calendar_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$calendarServiceHash() => r'713b24b15d9cf0a5f04753ee02832021a0ed2ad6';

/// A provider for the [CalendarService].
///
/// Copied from [calendarService].
@ProviderFor(calendarService)
final calendarServiceProvider = Provider<CalendarService>.internal(
  calendarService,
  name: r'calendarServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$calendarServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef CalendarServiceRef = ProviderRef<CalendarService>;
String _$calendarNotifierHash() => r'2d5b26adffe87a2dd6d2d4702f45c5c5ba3fb68f';

/// See also [CalendarNotifier].
@ProviderFor(CalendarNotifier)
final calendarNotifierProvider = AutoDisposeAsyncNotifierProvider<
    CalendarNotifier, List<FollowUpModel>>.internal(
  CalendarNotifier.new,
  name: r'calendarNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$calendarNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$CalendarNotifier = AutoDisposeAsyncNotifier<List<FollowUpModel>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
