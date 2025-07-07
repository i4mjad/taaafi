// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ban_warning_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$banWarningFacadeHash() => r'b914d922eaff0710df10f2903c3418f73fe50264';

/// See also [banWarningFacade].
@ProviderFor(banWarningFacade)
final banWarningFacadeProvider = AutoDisposeProvider<BanWarningFacade>.internal(
  banWarningFacade,
  name: r'banWarningFacadeProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$banWarningFacadeHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef BanWarningFacadeRef = AutoDisposeProviderRef<BanWarningFacade>;
String _$deviceServiceHash() => r'7e01f2f49db004899c9d84710b7050bd05ed8d32';

/// See also [deviceService].
@ProviderFor(deviceService)
final deviceServiceProvider = AutoDisposeProvider<DeviceService>.internal(
  deviceService,
  name: r'deviceServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$deviceServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef DeviceServiceRef = AutoDisposeProviderRef<DeviceService>;
String _$currentUserBansHash() => r'a74389f0a94842eb4649b864ba866b1b2481daf4';

/// See also [currentUserBans].
@ProviderFor(currentUserBans)
final currentUserBansProvider = AutoDisposeFutureProvider<List<Ban>>.internal(
  currentUserBans,
  name: r'currentUserBansProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$currentUserBansHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CurrentUserBansRef = AutoDisposeFutureProviderRef<List<Ban>>;
String _$userBansHash() => r'872723d4f6c01daf914d78ed9f0b4a2e41438569';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [userBans].
@ProviderFor(userBans)
const userBansProvider = UserBansFamily();

/// See also [userBans].
class UserBansFamily extends Family<AsyncValue<List<Ban>>> {
  /// See also [userBans].
  const UserBansFamily();

  /// See also [userBans].
  UserBansProvider call(
    String userId,
  ) {
    return UserBansProvider(
      userId,
    );
  }

  @override
  UserBansProvider getProviderOverride(
    covariant UserBansProvider provider,
  ) {
    return call(
      provider.userId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'userBansProvider';
}

/// See also [userBans].
class UserBansProvider extends AutoDisposeFutureProvider<List<Ban>> {
  /// See also [userBans].
  UserBansProvider(
    String userId,
  ) : this._internal(
          (ref) => userBans(
            ref as UserBansRef,
            userId,
          ),
          from: userBansProvider,
          name: r'userBansProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$userBansHash,
          dependencies: UserBansFamily._dependencies,
          allTransitiveDependencies: UserBansFamily._allTransitiveDependencies,
          userId: userId,
        );

  UserBansProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.userId,
  }) : super.internal();

  final String userId;

  @override
  Override overrideWith(
    FutureOr<List<Ban>> Function(UserBansRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: UserBansProvider._internal(
        (ref) => create(ref as UserBansRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        userId: userId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<Ban>> createElement() {
    return _UserBansProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is UserBansProvider && other.userId == userId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, userId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin UserBansRef on AutoDisposeFutureProviderRef<List<Ban>> {
  /// The parameter `userId` of this provider.
  String get userId;
}

class _UserBansProviderElement
    extends AutoDisposeFutureProviderElement<List<Ban>> with UserBansRef {
  _UserBansProviderElement(super.provider);

  @override
  String get userId => (origin as UserBansProvider).userId;
}

String _$isCurrentUserBannedFromAppHash() =>
    r'f48cf61a76b4a98cedb044e3e33989d9250f9a6d';

/// See also [isCurrentUserBannedFromApp].
@ProviderFor(isCurrentUserBannedFromApp)
final isCurrentUserBannedFromAppProvider =
    AutoDisposeFutureProvider<bool>.internal(
  isCurrentUserBannedFromApp,
  name: r'isCurrentUserBannedFromAppProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$isCurrentUserBannedFromAppHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef IsCurrentUserBannedFromAppRef = AutoDisposeFutureProviderRef<bool>;
String _$currentUserWarningsHash() =>
    r'f68b4fe19396fd25277bfa940641156922b21b6f';

/// See also [currentUserWarnings].
@ProviderFor(currentUserWarnings)
final currentUserWarningsProvider =
    AutoDisposeFutureProvider<List<Warning>>.internal(
  currentUserWarnings,
  name: r'currentUserWarningsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$currentUserWarningsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CurrentUserWarningsRef = AutoDisposeFutureProviderRef<List<Warning>>;
String _$userWarningsHash() => r'f32c6c5871ab4faf3461631fd375ead35bfa270e';

/// See also [userWarnings].
@ProviderFor(userWarnings)
const userWarningsProvider = UserWarningsFamily();

/// See also [userWarnings].
class UserWarningsFamily extends Family<AsyncValue<List<Warning>>> {
  /// See also [userWarnings].
  const UserWarningsFamily();

  /// See also [userWarnings].
  UserWarningsProvider call(
    String userId,
  ) {
    return UserWarningsProvider(
      userId,
    );
  }

  @override
  UserWarningsProvider getProviderOverride(
    covariant UserWarningsProvider provider,
  ) {
    return call(
      provider.userId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'userWarningsProvider';
}

/// See also [userWarnings].
class UserWarningsProvider extends AutoDisposeFutureProvider<List<Warning>> {
  /// See also [userWarnings].
  UserWarningsProvider(
    String userId,
  ) : this._internal(
          (ref) => userWarnings(
            ref as UserWarningsRef,
            userId,
          ),
          from: userWarningsProvider,
          name: r'userWarningsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$userWarningsHash,
          dependencies: UserWarningsFamily._dependencies,
          allTransitiveDependencies:
              UserWarningsFamily._allTransitiveDependencies,
          userId: userId,
        );

  UserWarningsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.userId,
  }) : super.internal();

  final String userId;

  @override
  Override overrideWith(
    FutureOr<List<Warning>> Function(UserWarningsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: UserWarningsProvider._internal(
        (ref) => create(ref as UserWarningsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        userId: userId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<Warning>> createElement() {
    return _UserWarningsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is UserWarningsProvider && other.userId == userId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, userId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin UserWarningsRef on AutoDisposeFutureProviderRef<List<Warning>> {
  /// The parameter `userId` of this provider.
  String get userId;
}

class _UserWarningsProviderElement
    extends AutoDisposeFutureProviderElement<List<Warning>>
    with UserWarningsRef {
  _UserWarningsProviderElement(super.provider);

  @override
  String get userId => (origin as UserWarningsProvider).userId;
}

String _$currentUserHighPriorityWarningsHash() =>
    r'84dee2714b01ef87fd60fab6f7685daeed15f99c';

/// See also [currentUserHighPriorityWarnings].
@ProviderFor(currentUserHighPriorityWarnings)
final currentUserHighPriorityWarningsProvider =
    AutoDisposeFutureProvider<List<Warning>>.internal(
  currentUserHighPriorityWarnings,
  name: r'currentUserHighPriorityWarningsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$currentUserHighPriorityWarningsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CurrentUserHighPriorityWarningsRef
    = AutoDisposeFutureProviderRef<List<Warning>>;
String _$appFeaturesHash() => r'2e1dd7341dd176eeb24fad8a76c0a8a5bf54e112';

/// See also [appFeatures].
@ProviderFor(appFeatures)
final appFeaturesProvider =
    AutoDisposeFutureProvider<List<AppFeature>>.internal(
  appFeatures,
  name: r'appFeaturesProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$appFeaturesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AppFeaturesRef = AutoDisposeFutureProviderRef<List<AppFeature>>;
String _$featureAccessHash() => r'478e5bc13bf28d57caf9d5cb37d31ab80e896d82';

/// See also [featureAccess].
@ProviderFor(featureAccess)
final featureAccessProvider =
    AutoDisposeFutureProvider<Map<String, bool>>.internal(
  featureAccess,
  name: r'featureAccessProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$featureAccessHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FeatureAccessRef = AutoDisposeFutureProviderRef<Map<String, bool>>;
String _$currentDeviceIdHash() => r'7ed24078a1d7356374ad25f20954e24d89c1ccfe';

/// See also [currentDeviceId].
@ProviderFor(currentDeviceId)
final currentDeviceIdProvider = AutoDisposeFutureProvider<String>.internal(
  currentDeviceId,
  name: r'currentDeviceIdProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$currentDeviceIdHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CurrentDeviceIdRef = AutoDisposeFutureProviderRef<String>;
String _$currentUserDeviceIdsHash() =>
    r'f7f7c11dacaeb1f65904802fe6e2833686488f6a';

/// See also [currentUserDeviceIds].
@ProviderFor(currentUserDeviceIds)
final currentUserDeviceIdsProvider =
    AutoDisposeFutureProvider<List<String>>.internal(
  currentUserDeviceIds,
  name: r'currentUserDeviceIdsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$currentUserDeviceIdsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CurrentUserDeviceIdsRef = AutoDisposeFutureProviderRef<List<String>>;
String _$deviceViolationHistoryHash() =>
    r'c456ee39df8689803595c116731a94bb993b25c0';

/// See also [deviceViolationHistory].
@ProviderFor(deviceViolationHistory)
const deviceViolationHistoryProvider = DeviceViolationHistoryFamily();

/// See also [deviceViolationHistory].
class DeviceViolationHistoryFamily
    extends Family<AsyncValue<Map<String, List<dynamic>>>> {
  /// See also [deviceViolationHistory].
  const DeviceViolationHistoryFamily();

  /// See also [deviceViolationHistory].
  DeviceViolationHistoryProvider call(
    String userId,
  ) {
    return DeviceViolationHistoryProvider(
      userId,
    );
  }

  @override
  DeviceViolationHistoryProvider getProviderOverride(
    covariant DeviceViolationHistoryProvider provider,
  ) {
    return call(
      provider.userId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'deviceViolationHistoryProvider';
}

/// See also [deviceViolationHistory].
class DeviceViolationHistoryProvider
    extends AutoDisposeFutureProvider<Map<String, List<dynamic>>> {
  /// See also [deviceViolationHistory].
  DeviceViolationHistoryProvider(
    String userId,
  ) : this._internal(
          (ref) => deviceViolationHistory(
            ref as DeviceViolationHistoryRef,
            userId,
          ),
          from: deviceViolationHistoryProvider,
          name: r'deviceViolationHistoryProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$deviceViolationHistoryHash,
          dependencies: DeviceViolationHistoryFamily._dependencies,
          allTransitiveDependencies:
              DeviceViolationHistoryFamily._allTransitiveDependencies,
          userId: userId,
        );

  DeviceViolationHistoryProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.userId,
  }) : super.internal();

  final String userId;

  @override
  Override overrideWith(
    FutureOr<Map<String, List<dynamic>>> Function(
            DeviceViolationHistoryRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: DeviceViolationHistoryProvider._internal(
        (ref) => create(ref as DeviceViolationHistoryRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        userId: userId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<Map<String, List<dynamic>>> createElement() {
    return _DeviceViolationHistoryProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is DeviceViolationHistoryProvider && other.userId == userId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, userId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin DeviceViolationHistoryRef
    on AutoDisposeFutureProviderRef<Map<String, List<dynamic>>> {
  /// The parameter `userId` of this provider.
  String get userId;
}

class _DeviceViolationHistoryProviderElement
    extends AutoDisposeFutureProviderElement<Map<String, List<dynamic>>>
    with DeviceViolationHistoryRef {
  _DeviceViolationHistoryProviderElement(super.provider);

  @override
  String get userId => (origin as DeviceViolationHistoryProvider).userId;
}

String _$invalidateBanCacheHash() =>
    r'48e3e323cc1ceeeba1df9274626165f0d1d1845a';

/// Provider that invalidates ban-related cache when user changes
///
/// Copied from [invalidateBanCache].
@ProviderFor(invalidateBanCache)
final invalidateBanCacheProvider = AutoDisposeFutureProvider<void>.internal(
  invalidateBanCache,
  name: r'invalidateBanCacheProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$invalidateBanCacheHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef InvalidateBanCacheRef = AutoDisposeFutureProviderRef<void>;
String _$currentUserIdHash() => r'e72cfb0559323475253e573efd2f5ab2c0dadabb';

/// Provider for getting user ID safely
///
/// Copied from [currentUserId].
@ProviderFor(currentUserId)
final currentUserIdProvider = AutoDisposeProvider<String?>.internal(
  currentUserId,
  name: r'currentUserIdProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$currentUserIdHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CurrentUserIdRef = AutoDisposeProviderRef<String?>;
String _$userBanStatusNotifierHash() =>
    r'211cb3d5febb33a9098349765e675aa247800b1b';

abstract class _$UserBanStatusNotifier
    extends BuildlessAutoDisposeAsyncNotifier<bool> {
  late final String userId;

  FutureOr<bool> build(
    String userId,
  );
}

/// See also [UserBanStatusNotifier].
@ProviderFor(UserBanStatusNotifier)
const userBanStatusNotifierProvider = UserBanStatusNotifierFamily();

/// See also [UserBanStatusNotifier].
class UserBanStatusNotifierFamily extends Family<AsyncValue<bool>> {
  /// See also [UserBanStatusNotifier].
  const UserBanStatusNotifierFamily();

  /// See also [UserBanStatusNotifier].
  UserBanStatusNotifierProvider call(
    String userId,
  ) {
    return UserBanStatusNotifierProvider(
      userId,
    );
  }

  @override
  UserBanStatusNotifierProvider getProviderOverride(
    covariant UserBanStatusNotifierProvider provider,
  ) {
    return call(
      provider.userId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'userBanStatusNotifierProvider';
}

/// See also [UserBanStatusNotifier].
class UserBanStatusNotifierProvider
    extends AutoDisposeAsyncNotifierProviderImpl<UserBanStatusNotifier, bool> {
  /// See also [UserBanStatusNotifier].
  UserBanStatusNotifierProvider(
    String userId,
  ) : this._internal(
          () => UserBanStatusNotifier()..userId = userId,
          from: userBanStatusNotifierProvider,
          name: r'userBanStatusNotifierProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$userBanStatusNotifierHash,
          dependencies: UserBanStatusNotifierFamily._dependencies,
          allTransitiveDependencies:
              UserBanStatusNotifierFamily._allTransitiveDependencies,
          userId: userId,
        );

  UserBanStatusNotifierProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.userId,
  }) : super.internal();

  final String userId;

  @override
  FutureOr<bool> runNotifierBuild(
    covariant UserBanStatusNotifier notifier,
  ) {
    return notifier.build(
      userId,
    );
  }

  @override
  Override overrideWith(UserBanStatusNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: UserBanStatusNotifierProvider._internal(
        () => create()..userId = userId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        userId: userId,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<UserBanStatusNotifier, bool>
      createElement() {
    return _UserBanStatusNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is UserBanStatusNotifierProvider && other.userId == userId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, userId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin UserBanStatusNotifierRef on AutoDisposeAsyncNotifierProviderRef<bool> {
  /// The parameter `userId` of this provider.
  String get userId;
}

class _UserBanStatusNotifierProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<UserBanStatusNotifier, bool>
    with UserBanStatusNotifierRef {
  _UserBanStatusNotifierProviderElement(super.provider);

  @override
  String get userId => (origin as UserBanStatusNotifierProvider).userId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
