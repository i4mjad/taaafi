// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'streak_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$streakServiceHash() => r'26433ed34647705798d21f3c7881a9a8dcadb582';

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

typedef StreakServiceRef = ProviderRef<StreakService>;
String _$streakNotifierHash() => r'4244e77cd3c79f30254ccdd965fd8e73c55a4474';

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
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
