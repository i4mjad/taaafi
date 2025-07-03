// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'clean_ban_warning_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$banRepositoryHash() => r'764e1e55633465c1bf78a97c89724e2f83786077';

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

typedef BanRepositoryRef = AutoDisposeProviderRef<BanRepository>;
String _$warningRepositoryHash() => r'27f833d839702c5e217d77a7cb848962da2b3fc0';

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

typedef WarningRepositoryRef = AutoDisposeProviderRef<WarningRepository>;
String _$cleanBanServiceHash() => r'624d080114776f6cf744c26187c3042dc2c296f1';

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

typedef CleanBanServiceRef = AutoDisposeProviderRef<CleanBanService>;
String _$cleanWarningServiceHash() =>
    r'063b2206ee35c92fe21c69dd9f8642b82550c17b';

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

typedef CleanWarningServiceRef = AutoDisposeProviderRef<CleanWarningService>;
String _$currentUserBansHash() => r'6ce15ce0baa4611bd1798944ee5e8e0f2d9a7910';

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

typedef CurrentUserBansRef = AutoDisposeFutureProviderRef<List<Ban>>;
String _$currentUserWarningsHash() =>
    r'f3584727d793dd0a1871eec95b2c0eaf079bf645';

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

typedef CurrentUserWarningsRef = AutoDisposeFutureProviderRef<List<Warning>>;
String _$currentUserHighPriorityWarningsHash() =>
    r'39ef19aeee749eab7d7bccdf3bddbd4923efd1d5';

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

typedef CurrentUserHighPriorityWarningsRef
    = AutoDisposeFutureProviderRef<List<Warning>>;
String _$userBansHash() => r'047deb868a76745ec838bd903dd2ee8da0012fce';

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

String _$userWarningsHash() => r'4dce705f684429e15142b088ce31bfb551601586';

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
    r'ba144aa446796a3af273764749be6632b9264b0f';

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

typedef IsCurrentUserBannedFromAppRef = AutoDisposeFutureProviderRef<bool>;
String _$currentUserHasCriticalWarningsHash() =>
    r'3ac77259a8759c02d7e540d4bb7415f0f9fa9c92';

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

typedef CurrentUserHasCriticalWarningsRef = AutoDisposeFutureProviderRef<bool>;
String _$canCurrentUserAccessFeatureHash() =>
    r'bdc1ff84590650c9212f6cac60ee6da256a42564';

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
    r'34c9fb642d4142e2eceda002ccd3289d8cf67a67';

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
    r'4cba9cfece80d3e3912b203971f4cd5306e5e1c7';

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

typedef CurrentUserBanSummaryRef
    = AutoDisposeFutureProviderRef<BanStatusSummary>;
String _$currentUserWarningSummaryHash() =>
    r'09a5dedefefde281bfb9975b427c31e5441767cd';

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

typedef CurrentUserWarningSummaryRef
    = AutoDisposeFutureProviderRef<WarningStatusSummary>;
String _$currentUserBansStreamHash() =>
    r'3f1c2f192f8c36330c8804c1365a377d91792574';

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

typedef CurrentUserBansStreamRef = AutoDisposeStreamProviderRef<List<Ban>>;
String _$currentUserWarningsStreamHash() =>
    r'86000f285691177d5d07e8b3195e112b46de92d1';

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

typedef CurrentUserWarningsStreamRef
    = AutoDisposeStreamProviderRef<List<Warning>>;
String _$currentUserIdHash() => r'b575e143ac1ee8cf8f1271405e64bea0eb69034e';

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

typedef CurrentUserIdRef = AutoDisposeProviderRef<String?>;
String _$invalidateUserCacheHash() =>
    r'e00d4a2ff31e2d17e73f297072e49c8c1106def2';

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

typedef InvalidateUserCacheRef = AutoDisposeFutureProviderRef<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
