// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'streak_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$streakServiceHash() => r'08a66e159804428a944d4e84b7cf7a61a66a3cef';

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
String _$streakStreamHash() => r'b38affac66697b26cfbaaab6872f4622b0b90a61';

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
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
