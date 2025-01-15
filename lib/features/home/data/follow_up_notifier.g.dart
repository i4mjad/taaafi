// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'follow_up_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$followUpServiceHash() => r'39d8733ce0b0195e1201784890f539af2b528339';

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
String _$followUpNotifierHash() => r'6b878a9410c989337654068224ef230a31cde10c';

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
