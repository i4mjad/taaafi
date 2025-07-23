// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'follow_up_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$followUpServiceHash() => r'4b3c8909cfdee0a1ba757eb312e8a1ab78e85188';

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

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FollowUpServiceRef = ProviderRef<FollowUpService>;
String _$followUpNotifierHash() => r'32e2ca38064a88191cc8817671c8de8946b253cc';

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
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
