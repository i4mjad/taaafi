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
String _$statisticsStreamHash() => r'89d2b69231698348f8427f114e52cc66639c691c';

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

typedef StatisticsStreamRef = AutoDisposeStreamProviderRef<UserStatisticsModel>;
String _$statisticsNotifierHash() =>
    r'e6af60aa58cad44649975659a62ec4d84baae95a';

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
