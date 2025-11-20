// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'referral_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$firestoreHash() => r'61fd2e037f3bfe7d2e52f293c7f2176ebebe5ac3';

/// See also [firestore].
@ProviderFor(firestore)
final firestoreProvider = AutoDisposeProvider<FirebaseFirestore>.internal(
  firestore,
  name: r'firestoreProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$firestoreHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FirestoreRef = AutoDisposeProviderRef<FirebaseFirestore>;
String _$functionsHash() => r'f10185eab19f5ef6af456521845113246a8e222a';

/// See also [functions].
@ProviderFor(functions)
final functionsProvider = AutoDisposeProvider<FirebaseFunctions>.internal(
  functions,
  name: r'functionsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$functionsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FunctionsRef = AutoDisposeProviderRef<FirebaseFunctions>;
String _$referralRepositoryHash() =>
    r'3adfe7b29796275e83a711e0ec4170995a10f749';

/// See also [referralRepository].
@ProviderFor(referralRepository)
final referralRepositoryProvider =
    AutoDisposeProvider<ReferralRepository>.internal(
  referralRepository,
  name: r'referralRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$referralRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ReferralRepositoryRef = AutoDisposeProviderRef<ReferralRepository>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
