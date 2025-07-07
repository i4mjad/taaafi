// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'statistics_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$statisticsServiceHash() => r'1b1602f9ccca99fbf519c2c108c813ef256165d9';

/// See also [statisticsService].
@ProviderFor(statisticsService)
final statisticsServiceProvider = Provider<StatisticsService>.internal(
  statisticsService,
  name: r'statisticsServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$statisticsServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef StatisticsServiceRef = ProviderRef<StatisticsService>;
String _$statisticsStreamHash() => r'ea7bd49682105ecd931a4b4376d603c05a575e0b';

/// See also [statisticsStream].
@ProviderFor(statisticsStream)
final statisticsStreamProvider =
    AutoDisposeStreamProvider<UserStatisticsModel>.internal(
  statisticsStream,
  name: r'statisticsStreamProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$statisticsStreamHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef StatisticsStreamRef = AutoDisposeStreamProviderRef<UserStatisticsModel>;
String _$statisticsNotifierHash() =>
    r'19637fab26009bcc2a456fd2f9d65d405dc86fc1';

/// See also [StatisticsNotifier].
@ProviderFor(StatisticsNotifier)
final statisticsNotifierProvider = AutoDisposeAsyncNotifierProvider<
    StatisticsNotifier, UserStatistics>.internal(
  StatisticsNotifier.new,
  name: r'statisticsNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$statisticsNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$StatisticsNotifier = AutoDisposeAsyncNotifier<UserStatistics>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
