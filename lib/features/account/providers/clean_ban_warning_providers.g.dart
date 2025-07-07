// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'clean_ban_warning_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$banRepositoryHash() => r'0e1c36578a4271979b8f475a4ddeda6ae230d166';

/// See also [banRepository].
@ProviderFor(banRepository)
final banRepositoryProvider = AutoDisposeProvider<BanRepository>.internal(
  banRepository,
  name: r'banRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$banRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef BanRepositoryRef = AutoDisposeProviderRef<BanRepository>;
String _$warningRepositoryHash() => r'691a2e8a2a6b4ea228c0257c4c1d9ebba94c9d5a';

/// See also [warningRepository].
@ProviderFor(warningRepository)
final warningRepositoryProvider =
    AutoDisposeProvider<WarningRepository>.internal(
  warningRepository,
  name: r'warningRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$warningRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef WarningRepositoryRef = AutoDisposeProviderRef<WarningRepository>;
String _$cleanBanServiceHash() => r'db489e35faa1f37f3c3e68fcac1d0511b9559b03';

/// See also [cleanBanService].
@ProviderFor(cleanBanService)
final cleanBanServiceProvider = AutoDisposeProvider<CleanBanService>.internal(
  cleanBanService,
  name: r'cleanBanServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$cleanBanServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CleanBanServiceRef = AutoDisposeProviderRef<CleanBanService>;
String _$cleanWarningServiceHash() =>
    r'10304d969cb84a56db760d97bff390fd849c2bc1';

/// See also [cleanWarningService].
@ProviderFor(cleanWarningService)
final cleanWarningServiceProvider =
    AutoDisposeProvider<CleanWarningService>.internal(
  cleanWarningService,
  name: r'cleanWarningServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$cleanWarningServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CleanWarningServiceRef = AutoDisposeProviderRef<CleanWarningService>;
String _$currentUserBansHash() => r'd2f7f858e394dc2b9d4001cb2b7f6e2a516d3c25';

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
String _$currentUserWarningsHash() =>
    r'7ff15266692d2aaf20844ff5567c2d93a323ce69';

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
String _$currentUserHighPriorityWarningsHash() =>
    r'fae4dae388c99fafe882c881ce52bada9ffb11f1';

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
String _$userBansHash() => r'bc4390d159bbe35d4dbcb614c7fd938418a41f79';

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

String _$userWarningsHash() => r'1b59696c57f6dcdd5ca17a579d7e8f21b66f46dd';

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

String _$isCurrentUserBannedFromAppHash() =>
    r'9fcb995a3d01ed3705707f2287f02a037e5b22fb';

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
String _$currentUserHasCriticalWarningsHash() =>
    r'4955073876bcc13491eb1a600b39be5454a25d36';

/// See also [currentUserHasCriticalWarnings].
@ProviderFor(currentUserHasCriticalWarnings)
final currentUserHasCriticalWarningsProvider =
    AutoDisposeFutureProvider<bool>.internal(
  currentUserHasCriticalWarnings,
  name: r'currentUserHasCriticalWarningsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$currentUserHasCriticalWarningsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CurrentUserHasCriticalWarningsRef = AutoDisposeFutureProviderRef<bool>;
String _$canCurrentUserAccessFeatureHash() =>
    r'2da1fe2e69b91dca9ea716a30ab557a65d7864f6';

/// See also [canCurrentUserAccessFeature].
@ProviderFor(canCurrentUserAccessFeature)
const canCurrentUserAccessFeatureProvider = CanCurrentUserAccessFeatureFamily();

/// See also [canCurrentUserAccessFeature].
class CanCurrentUserAccessFeatureFamily extends Family<AsyncValue<bool>> {
  /// See also [canCurrentUserAccessFeature].
  const CanCurrentUserAccessFeatureFamily();

  /// See also [canCurrentUserAccessFeature].
  CanCurrentUserAccessFeatureProvider call(
    String featureUniqueName,
  ) {
    return CanCurrentUserAccessFeatureProvider(
      featureUniqueName,
    );
  }

  @override
  CanCurrentUserAccessFeatureProvider getProviderOverride(
    covariant CanCurrentUserAccessFeatureProvider provider,
  ) {
    return call(
      provider.featureUniqueName,
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
  String? get name => r'canCurrentUserAccessFeatureProvider';
}

/// See also [canCurrentUserAccessFeature].
class CanCurrentUserAccessFeatureProvider
    extends AutoDisposeFutureProvider<bool> {
  /// See also [canCurrentUserAccessFeature].
  CanCurrentUserAccessFeatureProvider(
    String featureUniqueName,
  ) : this._internal(
          (ref) => canCurrentUserAccessFeature(
            ref as CanCurrentUserAccessFeatureRef,
            featureUniqueName,
          ),
          from: canCurrentUserAccessFeatureProvider,
          name: r'canCurrentUserAccessFeatureProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$canCurrentUserAccessFeatureHash,
          dependencies: CanCurrentUserAccessFeatureFamily._dependencies,
          allTransitiveDependencies:
              CanCurrentUserAccessFeatureFamily._allTransitiveDependencies,
          featureUniqueName: featureUniqueName,
        );

  CanCurrentUserAccessFeatureProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.featureUniqueName,
  }) : super.internal();

  final String featureUniqueName;

  @override
  Override overrideWith(
    FutureOr<bool> Function(CanCurrentUserAccessFeatureRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: CanCurrentUserAccessFeatureProvider._internal(
        (ref) => create(ref as CanCurrentUserAccessFeatureRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        featureUniqueName: featureUniqueName,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<bool> createElement() {
    return _CanCurrentUserAccessFeatureProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is CanCurrentUserAccessFeatureProvider &&
        other.featureUniqueName == featureUniqueName;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, featureUniqueName.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin CanCurrentUserAccessFeatureRef on AutoDisposeFutureProviderRef<bool> {
  /// The parameter `featureUniqueName` of this provider.
  String get featureUniqueName;
}

class _CanCurrentUserAccessFeatureProviderElement
    extends AutoDisposeFutureProviderElement<bool>
    with CanCurrentUserAccessFeatureRef {
  _CanCurrentUserAccessFeatureProviderElement(super.provider);

  @override
  String get featureUniqueName =>
      (origin as CanCurrentUserAccessFeatureProvider).featureUniqueName;
}

String _$currentUserFeatureBanHash() =>
    r'c34f9bf77f704887ffd06064edad673c76952e96';

/// See also [currentUserFeatureBan].
@ProviderFor(currentUserFeatureBan)
const currentUserFeatureBanProvider = CurrentUserFeatureBanFamily();

/// See also [currentUserFeatureBan].
class CurrentUserFeatureBanFamily extends Family<AsyncValue<Ban?>> {
  /// See also [currentUserFeatureBan].
  const CurrentUserFeatureBanFamily();

  /// See also [currentUserFeatureBan].
  CurrentUserFeatureBanProvider call(
    String featureUniqueName,
  ) {
    return CurrentUserFeatureBanProvider(
      featureUniqueName,
    );
  }

  @override
  CurrentUserFeatureBanProvider getProviderOverride(
    covariant CurrentUserFeatureBanProvider provider,
  ) {
    return call(
      provider.featureUniqueName,
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
  String? get name => r'currentUserFeatureBanProvider';
}

/// See also [currentUserFeatureBan].
class CurrentUserFeatureBanProvider extends AutoDisposeFutureProvider<Ban?> {
  /// See also [currentUserFeatureBan].
  CurrentUserFeatureBanProvider(
    String featureUniqueName,
  ) : this._internal(
          (ref) => currentUserFeatureBan(
            ref as CurrentUserFeatureBanRef,
            featureUniqueName,
          ),
          from: currentUserFeatureBanProvider,
          name: r'currentUserFeatureBanProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$currentUserFeatureBanHash,
          dependencies: CurrentUserFeatureBanFamily._dependencies,
          allTransitiveDependencies:
              CurrentUserFeatureBanFamily._allTransitiveDependencies,
          featureUniqueName: featureUniqueName,
        );

  CurrentUserFeatureBanProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.featureUniqueName,
  }) : super.internal();

  final String featureUniqueName;

  @override
  Override overrideWith(
    FutureOr<Ban?> Function(CurrentUserFeatureBanRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: CurrentUserFeatureBanProvider._internal(
        (ref) => create(ref as CurrentUserFeatureBanRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        featureUniqueName: featureUniqueName,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<Ban?> createElement() {
    return _CurrentUserFeatureBanProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is CurrentUserFeatureBanProvider &&
        other.featureUniqueName == featureUniqueName;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, featureUniqueName.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin CurrentUserFeatureBanRef on AutoDisposeFutureProviderRef<Ban?> {
  /// The parameter `featureUniqueName` of this provider.
  String get featureUniqueName;
}

class _CurrentUserFeatureBanProviderElement
    extends AutoDisposeFutureProviderElement<Ban?>
    with CurrentUserFeatureBanRef {
  _CurrentUserFeatureBanProviderElement(super.provider);

  @override
  String get featureUniqueName =>
      (origin as CurrentUserFeatureBanProvider).featureUniqueName;
}

String _$currentUserBanSummaryHash() =>
    r'f0f18fdafe168565f489619c52fd3f994bdf30ba';

/// See also [currentUserBanSummary].
@ProviderFor(currentUserBanSummary)
final currentUserBanSummaryProvider =
    AutoDisposeFutureProvider<BanStatusSummary>.internal(
  currentUserBanSummary,
  name: r'currentUserBanSummaryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$currentUserBanSummaryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CurrentUserBanSummaryRef
    = AutoDisposeFutureProviderRef<BanStatusSummary>;
String _$currentUserWarningSummaryHash() =>
    r'd93774e5e006de8d1dd3309e87709f369299e594';

/// See also [currentUserWarningSummary].
@ProviderFor(currentUserWarningSummary)
final currentUserWarningSummaryProvider =
    AutoDisposeFutureProvider<WarningStatusSummary>.internal(
  currentUserWarningSummary,
  name: r'currentUserWarningSummaryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$currentUserWarningSummaryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CurrentUserWarningSummaryRef
    = AutoDisposeFutureProviderRef<WarningStatusSummary>;
String _$currentUserBansStreamHash() =>
    r'1bce1e2b69404fc8b46c7c8b6c177b9dd0858d8c';

/// See also [currentUserBansStream].
@ProviderFor(currentUserBansStream)
final currentUserBansStreamProvider =
    AutoDisposeStreamProvider<List<Ban>>.internal(
  currentUserBansStream,
  name: r'currentUserBansStreamProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$currentUserBansStreamHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CurrentUserBansStreamRef = AutoDisposeStreamProviderRef<List<Ban>>;
String _$currentUserWarningsStreamHash() =>
    r'24b63b9ffd3cbe166afbe65de9f508031a1b267c';

/// See also [currentUserWarningsStream].
@ProviderFor(currentUserWarningsStream)
final currentUserWarningsStreamProvider =
    AutoDisposeStreamProvider<List<Warning>>.internal(
  currentUserWarningsStream,
  name: r'currentUserWarningsStreamProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$currentUserWarningsStreamHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CurrentUserWarningsStreamRef
    = AutoDisposeStreamProviderRef<List<Warning>>;
String _$currentUserIdHash() => r'e72cfb0559323475253e573efd2f5ab2c0dadabb';

/// See also [currentUserId].
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
String _$invalidateUserCacheHash() =>
    r'0eabefd8ec4e202ff0732e2a46cf0bc93ba62d90';

/// Provider that invalidates cache when user changes
///
/// Copied from [invalidateUserCache].
@ProviderFor(invalidateUserCache)
final invalidateUserCacheProvider = AutoDisposeFutureProvider<void>.internal(
  invalidateUserCache,
  name: r'invalidateUserCacheProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$invalidateUserCacheHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef InvalidateUserCacheRef = AutoDisposeFutureProviderRef<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
