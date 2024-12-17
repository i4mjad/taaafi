// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$firebaseAuthHash() => r'cff15592c2b2540ecca81d6450d8034b91548302';

/// See also [firebaseAuth].
@ProviderFor(firebaseAuth)
final firebaseAuthProvider = AutoDisposeProvider<FirebaseAuth>.internal(
  firebaseAuth,
  name: r'firebaseAuthProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$firebaseAuthHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef FirebaseAuthRef = AutoDisposeProviderRef<FirebaseAuth>;
String _$userProfileNotifierHash() =>
    r'282caed42dd6c8caddb098145f940fcd72e36305';

/// See also [UserProfileNotifier].
@ProviderFor(UserProfileNotifier)
final userProfileNotifierProvider = AutoDisposeAsyncNotifierProvider<
    UserProfileNotifier, UserProfile?>.internal(
  UserProfileNotifier.new,
  name: r'userProfileNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$userProfileNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$UserProfileNotifier = AutoDisposeAsyncNotifier<UserProfile?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
