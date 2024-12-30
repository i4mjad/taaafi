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
String _$streakNotifierHash() => r'95a64cbd5215d181cb361f6e1daf697d4875deba';

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
