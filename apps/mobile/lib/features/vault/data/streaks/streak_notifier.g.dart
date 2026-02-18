// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'streak_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$streakServiceHash() => r'7545b9f1dd782eea64de35d1afa83cd787f12b71';

/// See also [streakService].
@ProviderFor(streakService)
final streakServiceProvider = Provider<StreakService>.internal(
  streakService,
  name: r'streakServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$streakServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef StreakServiceRef = ProviderRef<StreakService>;
String _$streakStreamHash() => r'ac838a05fc12b13041257cfa6b2b4817eb8adec3';

/// See also [streakStream].
@ProviderFor(streakStream)
final streakStreamProvider =
    AutoDisposeStreamProvider<StreakStatistics>.internal(
  streakStream,
  name: r'streakStreamProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$streakStreamHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef StreakStreamRef = AutoDisposeStreamProviderRef<StreakStatistics>;
String _$streakNotifierHash() => r'bafd0e9362d12abd850366253ec40a01d6f8f1f1';

/// See also [StreakNotifier].
@ProviderFor(StreakNotifier)
final streakNotifierProvider =
    AutoDisposeAsyncNotifierProvider<StreakNotifier, StreakStatistics>.internal(
  StreakNotifier.new,
  name: r'streakNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$streakNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$StreakNotifier = AutoDisposeAsyncNotifier<StreakStatistics>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
