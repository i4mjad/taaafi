// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$activityRepositoryHash() =>
    r'51e136acf3d6521702b06237e2343c0adb3073b0';

/// See also [activityRepository].
@ProviderFor(activityRepository)
final activityRepositoryProvider = Provider<ActivityRepository>.internal(
  activityRepository,
  name: r'activityRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$activityRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef ActivityRepositoryRef = ProviderRef<ActivityRepository>;
String _$firebaseAuthHash() => r'46c40b7c5cf8ab936c0daa96a6af106bd2ae5d51';

/// See also [firebaseAuth].
@ProviderFor(firebaseAuth)
final firebaseAuthProvider = Provider<FirebaseAuth>.internal(
  firebaseAuth,
  name: r'firebaseAuthProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$firebaseAuthHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef FirebaseAuthRef = ProviderRef<FirebaseAuth>;
String _$firestoreHash() => r'e271f8f7be694ee819f397232f4d140c15a5f921';

/// See also [firestore].
@ProviderFor(firestore)
final firestoreProvider = Provider<FirebaseFirestore>.internal(
  firestore,
  name: r'firestoreProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$firestoreHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef FirestoreRef = ProviderRef<FirebaseFirestore>;
String _$activityServiceHash() => r'a95a99fead96df2dbcb086a6e5cd93191570b277';

/// See also [activityService].
@ProviderFor(activityService)
final activityServiceProvider = AutoDisposeProvider<ActivityService>.internal(
  activityService,
  name: r'activityServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$activityServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef ActivityServiceRef = AutoDisposeProviderRef<ActivityService>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
