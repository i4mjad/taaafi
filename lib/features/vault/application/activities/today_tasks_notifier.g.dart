// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'today_tasks_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$todayTasksStreamHash() => r'd3b28d39ed7ba62fd4f1dbf61967a982e31f2c13';

/// See also [todayTasksStream].
@ProviderFor(todayTasksStream)
final todayTasksStreamProvider =
    AutoDisposeStreamProvider<List<OngoingActivityTask>>.internal(
  todayTasksStream,
  name: r'todayTasksStreamProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$todayTasksStreamHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef TodayTasksStreamRef
    = AutoDisposeStreamProviderRef<List<OngoingActivityTask>>;
String _$todayTasksHash() => r'fd4e264b47341e6b0a851b29d4d7cf64a7416b74';

/// See also [TodayTasks].
@ProviderFor(TodayTasks)
final todayTasksProvider = AutoDisposeNotifierProvider<TodayTasks,
    Map<String, OngoingActivityTask>>.internal(
  TodayTasks.new,
  name: r'todayTasksProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$todayTasksHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$TodayTasks = AutoDisposeNotifier<Map<String, OngoingActivityTask>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
