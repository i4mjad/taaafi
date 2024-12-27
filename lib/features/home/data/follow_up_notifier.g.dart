// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'follow_up_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$followUpServiceHash() => r'7ccd2d00203752adf99ee2e2824451649369b73e';

/// See also [followUpService].
@ProviderFor(followUpService)
final followUpServiceProvider = Provider<FollowUpService>.internal(
  followUpService,
  name: r'followUpServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$followUpServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef FollowUpServiceRef = ProviderRef<FollowUpService>;
String _$followUpNotifierHash() => r'f3f73d984fc4e02a61e11ff3e1dc1cb52e5f9427';

/// See also [FollowUpNotifier].
@ProviderFor(FollowUpNotifier)
final followUpNotifierProvider = AutoDisposeAsyncNotifierProvider<
    FollowUpNotifier, List<FollowUpModel>>.internal(
  FollowUpNotifier.new,
  name: r'followUpNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$followUpNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$FollowUpNotifier = AutoDisposeAsyncNotifier<List<FollowUpModel>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
