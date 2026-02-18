// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calendar_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$calendarStreamHash() => r'94208e18706fb076a84b9117c1927dba281e8aae';

/// See also [calendarStream].
@ProviderFor(calendarStream)
final calendarStreamProvider =
    AutoDisposeStreamProvider<List<FollowUpModel>>.internal(
  calendarStream,
  name: r'calendarStreamProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$calendarStreamHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CalendarStreamRef = AutoDisposeStreamProviderRef<List<FollowUpModel>>;
String _$calendarServiceHash() => r'32bc84c92297ec661e415a7928d1ae82ab00a59e';

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

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CalendarServiceRef = ProviderRef<CalendarService>;
String _$calendarNotifierHash() => r'87eb31d48e0e3bd06ca4953504747b1a7b75e063';

/// See also [CalendarNotifier].
@ProviderFor(CalendarNotifier)
final calendarNotifierProvider =
    AsyncNotifierProvider<CalendarNotifier, List<FollowUpModel>>.internal(
  CalendarNotifier.new,
  name: r'calendarNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$calendarNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$CalendarNotifier = AsyncNotifier<List<FollowUpModel>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
