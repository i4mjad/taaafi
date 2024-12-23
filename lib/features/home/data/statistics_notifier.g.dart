// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'statistics_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$statisticsServiceHash() => r'f597bc53b0e59b306ce033a594a8fa001f5219c7';

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

typedef StatisticsServiceRef = ProviderRef<StatisticsService>;
String _$statisticsNotifierHash() =>
    r'e187e0b9c512bcdcf26d50943a805fc8996cb2b0';

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
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
