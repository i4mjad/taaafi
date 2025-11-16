// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'updates_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$firestoreHash() => r'0e25e335c5657f593fc1baf3d9fd026e70bca7fa';

/// Firestore instance provider
///
/// Copied from [firestore].
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
String _$updatesRepositoryHash() => r'ab5672a3a5db2e124f2f5b9f8f71ce0df0cf496d';

/// Updates repository provider
///
/// Copied from [updatesRepository].
@ProviderFor(updatesRepository)
final updatesRepositoryProvider =
    AutoDisposeProvider<UpdatesRepository>.internal(
  updatesRepository,
  name: r'updatesRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$updatesRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef UpdatesRepositoryRef = AutoDisposeProviderRef<UpdatesRepository>;
String _$followUpRepositoryHash() =>
    r'c7e4134ccc702ed9e7483e0b7cca08b480dbca1c';

/// Followup repository provider (for groups feature)
///
/// Copied from [followUpRepository].
@ProviderFor(followUpRepository)
final followUpRepositoryProvider =
    AutoDisposeProvider<FollowUpRepository>.internal(
  followUpRepository,
  name: r'followUpRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$followUpRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FollowUpRepositoryRef = AutoDisposeProviderRef<FollowUpRepository>;
String _$followupIntegrationServiceHash() =>
    r'd382a7ff91da2657843168d09678b98559f1fb94';

/// Followup integration service provider
///
/// Copied from [followupIntegrationService].
@ProviderFor(followupIntegrationService)
final followupIntegrationServiceProvider =
    AutoDisposeProvider<FollowupIntegrationService>.internal(
  followupIntegrationService,
  name: r'followupIntegrationServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$followupIntegrationServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FollowupIntegrationServiceRef
    = AutoDisposeProviderRef<FollowupIntegrationService>;
String _$updatesServiceHash() => r'e17549a64f25c956cd5864a05d2a50496b57ac01';

/// Updates service provider
///
/// Copied from [updatesService].
@ProviderFor(updatesService)
final updatesServiceProvider = AutoDisposeProvider<UpdatesService>.internal(
  updatesService,
  name: r'updatesServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$updatesServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef UpdatesServiceRef = AutoDisposeProviderRef<UpdatesService>;
String _$groupUpdatesHash() => r'627a4a3ce7088d1d6c17489efbaad7e33a0aea43';

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

/// Stream of all updates for a group
///
/// Copied from [groupUpdates].
@ProviderFor(groupUpdates)
const groupUpdatesProvider = GroupUpdatesFamily();

/// Stream of all updates for a group
///
/// Copied from [groupUpdates].
class GroupUpdatesFamily extends Family<AsyncValue<List<GroupUpdateEntity>>> {
  /// Stream of all updates for a group
  ///
  /// Copied from [groupUpdates].
  const GroupUpdatesFamily();

  /// Stream of all updates for a group
  ///
  /// Copied from [groupUpdates].
  GroupUpdatesProvider call(
    String groupId,
  ) {
    return GroupUpdatesProvider(
      groupId,
    );
  }

  @override
  GroupUpdatesProvider getProviderOverride(
    covariant GroupUpdatesProvider provider,
  ) {
    return call(
      provider.groupId,
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
  String? get name => r'groupUpdatesProvider';
}

/// Stream of all updates for a group
///
/// Copied from [groupUpdates].
class GroupUpdatesProvider
    extends AutoDisposeStreamProvider<List<GroupUpdateEntity>> {
  /// Stream of all updates for a group
  ///
  /// Copied from [groupUpdates].
  GroupUpdatesProvider(
    String groupId,
  ) : this._internal(
          (ref) => groupUpdates(
            ref as GroupUpdatesRef,
            groupId,
          ),
          from: groupUpdatesProvider,
          name: r'groupUpdatesProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$groupUpdatesHash,
          dependencies: GroupUpdatesFamily._dependencies,
          allTransitiveDependencies:
              GroupUpdatesFamily._allTransitiveDependencies,
          groupId: groupId,
        );

  GroupUpdatesProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.groupId,
  }) : super.internal();

  final String groupId;

  @override
  Override overrideWith(
    Stream<List<GroupUpdateEntity>> Function(GroupUpdatesRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: GroupUpdatesProvider._internal(
        (ref) => create(ref as GroupUpdatesRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        groupId: groupId,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<List<GroupUpdateEntity>> createElement() {
    return _GroupUpdatesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is GroupUpdatesProvider && other.groupId == groupId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, groupId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin GroupUpdatesRef on AutoDisposeStreamProviderRef<List<GroupUpdateEntity>> {
  /// The parameter `groupId` of this provider.
  String get groupId;
}

class _GroupUpdatesProviderElement
    extends AutoDisposeStreamProviderElement<List<GroupUpdateEntity>>
    with GroupUpdatesRef {
  _GroupUpdatesProviderElement(super.provider);

  @override
  String get groupId => (origin as GroupUpdatesProvider).groupId;
}

String _$recentUpdatesHash() => r'5791dde47b6f5d1f1538bb041a83f8f58059d88d';

/// Get recent updates with pagination
///
/// Copied from [recentUpdates].
@ProviderFor(recentUpdates)
const recentUpdatesProvider = RecentUpdatesFamily();

/// Get recent updates with pagination
///
/// Copied from [recentUpdates].
class RecentUpdatesFamily extends Family<AsyncValue<List<GroupUpdateEntity>>> {
  /// Get recent updates with pagination
  ///
  /// Copied from [recentUpdates].
  const RecentUpdatesFamily();

  /// Get recent updates with pagination
  ///
  /// Copied from [recentUpdates].
  RecentUpdatesProvider call(
    String groupId, {
    int limit = 20,
    DateTime? before,
  }) {
    return RecentUpdatesProvider(
      groupId,
      limit: limit,
      before: before,
    );
  }

  @override
  RecentUpdatesProvider getProviderOverride(
    covariant RecentUpdatesProvider provider,
  ) {
    return call(
      provider.groupId,
      limit: provider.limit,
      before: provider.before,
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
  String? get name => r'recentUpdatesProvider';
}

/// Get recent updates with pagination
///
/// Copied from [recentUpdates].
class RecentUpdatesProvider
    extends AutoDisposeFutureProvider<List<GroupUpdateEntity>> {
  /// Get recent updates with pagination
  ///
  /// Copied from [recentUpdates].
  RecentUpdatesProvider(
    String groupId, {
    int limit = 20,
    DateTime? before,
  }) : this._internal(
          (ref) => recentUpdates(
            ref as RecentUpdatesRef,
            groupId,
            limit: limit,
            before: before,
          ),
          from: recentUpdatesProvider,
          name: r'recentUpdatesProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$recentUpdatesHash,
          dependencies: RecentUpdatesFamily._dependencies,
          allTransitiveDependencies:
              RecentUpdatesFamily._allTransitiveDependencies,
          groupId: groupId,
          limit: limit,
          before: before,
        );

  RecentUpdatesProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.groupId,
    required this.limit,
    required this.before,
  }) : super.internal();

  final String groupId;
  final int limit;
  final DateTime? before;

  @override
  Override overrideWith(
    FutureOr<List<GroupUpdateEntity>> Function(RecentUpdatesRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: RecentUpdatesProvider._internal(
        (ref) => create(ref as RecentUpdatesRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        groupId: groupId,
        limit: limit,
        before: before,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<GroupUpdateEntity>> createElement() {
    return _RecentUpdatesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is RecentUpdatesProvider &&
        other.groupId == groupId &&
        other.limit == limit &&
        other.before == before;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, groupId.hashCode);
    hash = _SystemHash.combine(hash, limit.hashCode);
    hash = _SystemHash.combine(hash, before.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin RecentUpdatesRef
    on AutoDisposeFutureProviderRef<List<GroupUpdateEntity>> {
  /// The parameter `groupId` of this provider.
  String get groupId;

  /// The parameter `limit` of this provider.
  int get limit;

  /// The parameter `before` of this provider.
  DateTime? get before;
}

class _RecentUpdatesProviderElement
    extends AutoDisposeFutureProviderElement<List<GroupUpdateEntity>>
    with RecentUpdatesRef {
  _RecentUpdatesProviderElement(super.provider);

  @override
  String get groupId => (origin as RecentUpdatesProvider).groupId;
  @override
  int get limit => (origin as RecentUpdatesProvider).limit;
  @override
  DateTime? get before => (origin as RecentUpdatesProvider).before;
}

String _$updateByIdHash() => r'af99936c3058c09999ce4704ce8faa71c0a1d888';

/// Get update by ID
///
/// Copied from [updateById].
@ProviderFor(updateById)
const updateByIdProvider = UpdateByIdFamily();

/// Get update by ID
///
/// Copied from [updateById].
class UpdateByIdFamily extends Family<AsyncValue<GroupUpdateEntity?>> {
  /// Get update by ID
  ///
  /// Copied from [updateById].
  const UpdateByIdFamily();

  /// Get update by ID
  ///
  /// Copied from [updateById].
  UpdateByIdProvider call(
    String updateId,
  ) {
    return UpdateByIdProvider(
      updateId,
    );
  }

  @override
  UpdateByIdProvider getProviderOverride(
    covariant UpdateByIdProvider provider,
  ) {
    return call(
      provider.updateId,
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
  String? get name => r'updateByIdProvider';
}

/// Get update by ID
///
/// Copied from [updateById].
class UpdateByIdProvider extends AutoDisposeFutureProvider<GroupUpdateEntity?> {
  /// Get update by ID
  ///
  /// Copied from [updateById].
  UpdateByIdProvider(
    String updateId,
  ) : this._internal(
          (ref) => updateById(
            ref as UpdateByIdRef,
            updateId,
          ),
          from: updateByIdProvider,
          name: r'updateByIdProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$updateByIdHash,
          dependencies: UpdateByIdFamily._dependencies,
          allTransitiveDependencies:
              UpdateByIdFamily._allTransitiveDependencies,
          updateId: updateId,
        );

  UpdateByIdProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.updateId,
  }) : super.internal();

  final String updateId;

  @override
  Override overrideWith(
    FutureOr<GroupUpdateEntity?> Function(UpdateByIdRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: UpdateByIdProvider._internal(
        (ref) => create(ref as UpdateByIdRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        updateId: updateId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<GroupUpdateEntity?> createElement() {
    return _UpdateByIdProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is UpdateByIdProvider && other.updateId == updateId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, updateId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin UpdateByIdRef on AutoDisposeFutureProviderRef<GroupUpdateEntity?> {
  /// The parameter `updateId` of this provider.
  String get updateId;
}

class _UpdateByIdProviderElement
    extends AutoDisposeFutureProviderElement<GroupUpdateEntity?>
    with UpdateByIdRef {
  _UpdateByIdProviderElement(super.provider);

  @override
  String get updateId => (origin as UpdateByIdProvider).updateId;
}

String _$latestUpdatesHash() => r'7bf28ca75f428eed9947beaa7c5aa0f6def6762e';

/// Stream of latest N updates for group (for real-time feed)
///
/// Copied from [latestUpdates].
@ProviderFor(latestUpdates)
const latestUpdatesProvider = LatestUpdatesFamily();

/// Stream of latest N updates for group (for real-time feed)
///
/// Copied from [latestUpdates].
class LatestUpdatesFamily extends Family<AsyncValue<List<GroupUpdateEntity>>> {
  /// Stream of latest N updates for group (for real-time feed)
  ///
  /// Copied from [latestUpdates].
  const LatestUpdatesFamily();

  /// Stream of latest N updates for group (for real-time feed)
  ///
  /// Copied from [latestUpdates].
  LatestUpdatesProvider call(
    String groupId, {
    int limit = 5,
  }) {
    return LatestUpdatesProvider(
      groupId,
      limit: limit,
    );
  }

  @override
  LatestUpdatesProvider getProviderOverride(
    covariant LatestUpdatesProvider provider,
  ) {
    return call(
      provider.groupId,
      limit: provider.limit,
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
  String? get name => r'latestUpdatesProvider';
}

/// Stream of latest N updates for group (for real-time feed)
///
/// Copied from [latestUpdates].
class LatestUpdatesProvider
    extends AutoDisposeStreamProvider<List<GroupUpdateEntity>> {
  /// Stream of latest N updates for group (for real-time feed)
  ///
  /// Copied from [latestUpdates].
  LatestUpdatesProvider(
    String groupId, {
    int limit = 5,
  }) : this._internal(
          (ref) => latestUpdates(
            ref as LatestUpdatesRef,
            groupId,
            limit: limit,
          ),
          from: latestUpdatesProvider,
          name: r'latestUpdatesProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$latestUpdatesHash,
          dependencies: LatestUpdatesFamily._dependencies,
          allTransitiveDependencies:
              LatestUpdatesFamily._allTransitiveDependencies,
          groupId: groupId,
          limit: limit,
        );

  LatestUpdatesProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.groupId,
    required this.limit,
  }) : super.internal();

  final String groupId;
  final int limit;

  @override
  Override overrideWith(
    Stream<List<GroupUpdateEntity>> Function(LatestUpdatesRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: LatestUpdatesProvider._internal(
        (ref) => create(ref as LatestUpdatesRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        groupId: groupId,
        limit: limit,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<List<GroupUpdateEntity>> createElement() {
    return _LatestUpdatesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is LatestUpdatesProvider &&
        other.groupId == groupId &&
        other.limit == limit;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, groupId.hashCode);
    hash = _SystemHash.combine(hash, limit.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin LatestUpdatesRef
    on AutoDisposeStreamProviderRef<List<GroupUpdateEntity>> {
  /// The parameter `groupId` of this provider.
  String get groupId;

  /// The parameter `limit` of this provider.
  int get limit;
}

class _LatestUpdatesProviderElement
    extends AutoDisposeStreamProviderElement<List<GroupUpdateEntity>>
    with LatestUpdatesRef {
  _LatestUpdatesProviderElement(super.provider);

  @override
  String get groupId => (origin as LatestUpdatesProvider).groupId;
  @override
  int get limit => (origin as LatestUpdatesProvider).limit;
}

String _$userUpdatesHash() => r'e5a2317a77f34ceed2fc86f5a765031c48a97c3b';

/// Get user updates in a group
///
/// Copied from [userUpdates].
@ProviderFor(userUpdates)
const userUpdatesProvider = UserUpdatesFamily();

/// Get user updates in a group
///
/// Copied from [userUpdates].
class UserUpdatesFamily extends Family<AsyncValue<List<GroupUpdateEntity>>> {
  /// Get user updates in a group
  ///
  /// Copied from [userUpdates].
  const UserUpdatesFamily();

  /// Get user updates in a group
  ///
  /// Copied from [userUpdates].
  UserUpdatesProvider call(
    String groupId,
    String cpId, {
    int limit = 20,
  }) {
    return UserUpdatesProvider(
      groupId,
      cpId,
      limit: limit,
    );
  }

  @override
  UserUpdatesProvider getProviderOverride(
    covariant UserUpdatesProvider provider,
  ) {
    return call(
      provider.groupId,
      provider.cpId,
      limit: provider.limit,
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
  String? get name => r'userUpdatesProvider';
}

/// Get user updates in a group
///
/// Copied from [userUpdates].
class UserUpdatesProvider
    extends AutoDisposeFutureProvider<List<GroupUpdateEntity>> {
  /// Get user updates in a group
  ///
  /// Copied from [userUpdates].
  UserUpdatesProvider(
    String groupId,
    String cpId, {
    int limit = 20,
  }) : this._internal(
          (ref) => userUpdates(
            ref as UserUpdatesRef,
            groupId,
            cpId,
            limit: limit,
          ),
          from: userUpdatesProvider,
          name: r'userUpdatesProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$userUpdatesHash,
          dependencies: UserUpdatesFamily._dependencies,
          allTransitiveDependencies:
              UserUpdatesFamily._allTransitiveDependencies,
          groupId: groupId,
          cpId: cpId,
          limit: limit,
        );

  UserUpdatesProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.groupId,
    required this.cpId,
    required this.limit,
  }) : super.internal();

  final String groupId;
  final String cpId;
  final int limit;

  @override
  Override overrideWith(
    FutureOr<List<GroupUpdateEntity>> Function(UserUpdatesRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: UserUpdatesProvider._internal(
        (ref) => create(ref as UserUpdatesRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        groupId: groupId,
        cpId: cpId,
        limit: limit,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<GroupUpdateEntity>> createElement() {
    return _UserUpdatesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is UserUpdatesProvider &&
        other.groupId == groupId &&
        other.cpId == cpId &&
        other.limit == limit;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, groupId.hashCode);
    hash = _SystemHash.combine(hash, cpId.hashCode);
    hash = _SystemHash.combine(hash, limit.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin UserUpdatesRef on AutoDisposeFutureProviderRef<List<GroupUpdateEntity>> {
  /// The parameter `groupId` of this provider.
  String get groupId;

  /// The parameter `cpId` of this provider.
  String get cpId;

  /// The parameter `limit` of this provider.
  int get limit;
}

class _UserUpdatesProviderElement
    extends AutoDisposeFutureProviderElement<List<GroupUpdateEntity>>
    with UserUpdatesRef {
  _UserUpdatesProviderElement(super.provider);

  @override
  String get groupId => (origin as UserUpdatesProvider).groupId;
  @override
  String get cpId => (origin as UserUpdatesProvider).cpId;
  @override
  int get limit => (origin as UserUpdatesProvider).limit;
}

String _$updatesByTypeHash() => r'fa45ebfc7a0a68b46f682bf0465ee94a89aac62d';

/// Get updates by type
///
/// Copied from [updatesByType].
@ProviderFor(updatesByType)
const updatesByTypeProvider = UpdatesByTypeFamily();

/// Get updates by type
///
/// Copied from [updatesByType].
class UpdatesByTypeFamily extends Family<AsyncValue<List<GroupUpdateEntity>>> {
  /// Get updates by type
  ///
  /// Copied from [updatesByType].
  const UpdatesByTypeFamily();

  /// Get updates by type
  ///
  /// Copied from [updatesByType].
  UpdatesByTypeProvider call(
    String groupId,
    UpdateType type, {
    int limit = 20,
  }) {
    return UpdatesByTypeProvider(
      groupId,
      type,
      limit: limit,
    );
  }

  @override
  UpdatesByTypeProvider getProviderOverride(
    covariant UpdatesByTypeProvider provider,
  ) {
    return call(
      provider.groupId,
      provider.type,
      limit: provider.limit,
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
  String? get name => r'updatesByTypeProvider';
}

/// Get updates by type
///
/// Copied from [updatesByType].
class UpdatesByTypeProvider
    extends AutoDisposeFutureProvider<List<GroupUpdateEntity>> {
  /// Get updates by type
  ///
  /// Copied from [updatesByType].
  UpdatesByTypeProvider(
    String groupId,
    UpdateType type, {
    int limit = 20,
  }) : this._internal(
          (ref) => updatesByType(
            ref as UpdatesByTypeRef,
            groupId,
            type,
            limit: limit,
          ),
          from: updatesByTypeProvider,
          name: r'updatesByTypeProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$updatesByTypeHash,
          dependencies: UpdatesByTypeFamily._dependencies,
          allTransitiveDependencies:
              UpdatesByTypeFamily._allTransitiveDependencies,
          groupId: groupId,
          type: type,
          limit: limit,
        );

  UpdatesByTypeProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.groupId,
    required this.type,
    required this.limit,
  }) : super.internal();

  final String groupId;
  final UpdateType type;
  final int limit;

  @override
  Override overrideWith(
    FutureOr<List<GroupUpdateEntity>> Function(UpdatesByTypeRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: UpdatesByTypeProvider._internal(
        (ref) => create(ref as UpdatesByTypeRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        groupId: groupId,
        type: type,
        limit: limit,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<GroupUpdateEntity>> createElement() {
    return _UpdatesByTypeProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is UpdatesByTypeProvider &&
        other.groupId == groupId &&
        other.type == type &&
        other.limit == limit;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, groupId.hashCode);
    hash = _SystemHash.combine(hash, type.hashCode);
    hash = _SystemHash.combine(hash, limit.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin UpdatesByTypeRef
    on AutoDisposeFutureProviderRef<List<GroupUpdateEntity>> {
  /// The parameter `groupId` of this provider.
  String get groupId;

  /// The parameter `type` of this provider.
  UpdateType get type;

  /// The parameter `limit` of this provider.
  int get limit;
}

class _UpdatesByTypeProviderElement
    extends AutoDisposeFutureProviderElement<List<GroupUpdateEntity>>
    with UpdatesByTypeRef {
  _UpdatesByTypeProviderElement(super.provider);

  @override
  String get groupId => (origin as UpdatesByTypeProvider).groupId;
  @override
  UpdateType get type => (origin as UpdatesByTypeProvider).type;
  @override
  int get limit => (origin as UpdatesByTypeProvider).limit;
}

String _$pinnedUpdatesHash() => r'36008c2d494b0cf7021d1acf689962bc049a0010';

/// Get pinned updates for a group
///
/// Copied from [pinnedUpdates].
@ProviderFor(pinnedUpdates)
const pinnedUpdatesProvider = PinnedUpdatesFamily();

/// Get pinned updates for a group
///
/// Copied from [pinnedUpdates].
class PinnedUpdatesFamily extends Family<AsyncValue<List<GroupUpdateEntity>>> {
  /// Get pinned updates for a group
  ///
  /// Copied from [pinnedUpdates].
  const PinnedUpdatesFamily();

  /// Get pinned updates for a group
  ///
  /// Copied from [pinnedUpdates].
  PinnedUpdatesProvider call(
    String groupId,
  ) {
    return PinnedUpdatesProvider(
      groupId,
    );
  }

  @override
  PinnedUpdatesProvider getProviderOverride(
    covariant PinnedUpdatesProvider provider,
  ) {
    return call(
      provider.groupId,
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
  String? get name => r'pinnedUpdatesProvider';
}

/// Get pinned updates for a group
///
/// Copied from [pinnedUpdates].
class PinnedUpdatesProvider
    extends AutoDisposeFutureProvider<List<GroupUpdateEntity>> {
  /// Get pinned updates for a group
  ///
  /// Copied from [pinnedUpdates].
  PinnedUpdatesProvider(
    String groupId,
  ) : this._internal(
          (ref) => pinnedUpdates(
            ref as PinnedUpdatesRef,
            groupId,
          ),
          from: pinnedUpdatesProvider,
          name: r'pinnedUpdatesProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$pinnedUpdatesHash,
          dependencies: PinnedUpdatesFamily._dependencies,
          allTransitiveDependencies:
              PinnedUpdatesFamily._allTransitiveDependencies,
          groupId: groupId,
        );

  PinnedUpdatesProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.groupId,
  }) : super.internal();

  final String groupId;

  @override
  Override overrideWith(
    FutureOr<List<GroupUpdateEntity>> Function(PinnedUpdatesRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: PinnedUpdatesProvider._internal(
        (ref) => create(ref as PinnedUpdatesRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        groupId: groupId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<GroupUpdateEntity>> createElement() {
    return _PinnedUpdatesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PinnedUpdatesProvider && other.groupId == groupId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, groupId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin PinnedUpdatesRef
    on AutoDisposeFutureProviderRef<List<GroupUpdateEntity>> {
  /// The parameter `groupId` of this provider.
  String get groupId;
}

class _PinnedUpdatesProviderElement
    extends AutoDisposeFutureProviderElement<List<GroupUpdateEntity>>
    with PinnedUpdatesRef {
  _PinnedUpdatesProviderElement(super.provider);

  @override
  String get groupId => (origin as PinnedUpdatesProvider).groupId;
}

String _$updateCommentsHash() => r'f95c1cb3156bfd63b4b83c68fbb8858e20453795';

/// Stream of comments for an update
///
/// Copied from [updateComments].
@ProviderFor(updateComments)
const updateCommentsProvider = UpdateCommentsFamily();

/// Stream of comments for an update
///
/// Copied from [updateComments].
class UpdateCommentsFamily
    extends Family<AsyncValue<List<UpdateCommentEntity>>> {
  /// Stream of comments for an update
  ///
  /// Copied from [updateComments].
  const UpdateCommentsFamily();

  /// Stream of comments for an update
  ///
  /// Copied from [updateComments].
  UpdateCommentsProvider call(
    String updateId,
  ) {
    return UpdateCommentsProvider(
      updateId,
    );
  }

  @override
  UpdateCommentsProvider getProviderOverride(
    covariant UpdateCommentsProvider provider,
  ) {
    return call(
      provider.updateId,
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
  String? get name => r'updateCommentsProvider';
}

/// Stream of comments for an update
///
/// Copied from [updateComments].
class UpdateCommentsProvider
    extends AutoDisposeStreamProvider<List<UpdateCommentEntity>> {
  /// Stream of comments for an update
  ///
  /// Copied from [updateComments].
  UpdateCommentsProvider(
    String updateId,
  ) : this._internal(
          (ref) => updateComments(
            ref as UpdateCommentsRef,
            updateId,
          ),
          from: updateCommentsProvider,
          name: r'updateCommentsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$updateCommentsHash,
          dependencies: UpdateCommentsFamily._dependencies,
          allTransitiveDependencies:
              UpdateCommentsFamily._allTransitiveDependencies,
          updateId: updateId,
        );

  UpdateCommentsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.updateId,
  }) : super.internal();

  final String updateId;

  @override
  Override overrideWith(
    Stream<List<UpdateCommentEntity>> Function(UpdateCommentsRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: UpdateCommentsProvider._internal(
        (ref) => create(ref as UpdateCommentsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        updateId: updateId,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<List<UpdateCommentEntity>> createElement() {
    return _UpdateCommentsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is UpdateCommentsProvider && other.updateId == updateId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, updateId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin UpdateCommentsRef
    on AutoDisposeStreamProviderRef<List<UpdateCommentEntity>> {
  /// The parameter `updateId` of this provider.
  String get updateId;
}

class _UpdateCommentsProviderElement
    extends AutoDisposeStreamProviderElement<List<UpdateCommentEntity>>
    with UpdateCommentsRef {
  _UpdateCommentsProviderElement(super.provider);

  @override
  String get updateId => (origin as UpdateCommentsProvider).updateId;
}

String _$commentCountHash() => r'54b7a1a2519e27659ff70774ae4c32876110cf9d';

/// Get comment count for an update
///
/// Copied from [commentCount].
@ProviderFor(commentCount)
const commentCountProvider = CommentCountFamily();

/// Get comment count for an update
///
/// Copied from [commentCount].
class CommentCountFamily extends Family<AsyncValue<int>> {
  /// Get comment count for an update
  ///
  /// Copied from [commentCount].
  const CommentCountFamily();

  /// Get comment count for an update
  ///
  /// Copied from [commentCount].
  CommentCountProvider call(
    String updateId,
  ) {
    return CommentCountProvider(
      updateId,
    );
  }

  @override
  CommentCountProvider getProviderOverride(
    covariant CommentCountProvider provider,
  ) {
    return call(
      provider.updateId,
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
  String? get name => r'commentCountProvider';
}

/// Get comment count for an update
///
/// Copied from [commentCount].
class CommentCountProvider extends AutoDisposeFutureProvider<int> {
  /// Get comment count for an update
  ///
  /// Copied from [commentCount].
  CommentCountProvider(
    String updateId,
  ) : this._internal(
          (ref) => commentCount(
            ref as CommentCountRef,
            updateId,
          ),
          from: commentCountProvider,
          name: r'commentCountProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$commentCountHash,
          dependencies: CommentCountFamily._dependencies,
          allTransitiveDependencies:
              CommentCountFamily._allTransitiveDependencies,
          updateId: updateId,
        );

  CommentCountProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.updateId,
  }) : super.internal();

  final String updateId;

  @override
  Override overrideWith(
    FutureOr<int> Function(CommentCountRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: CommentCountProvider._internal(
        (ref) => create(ref as CommentCountRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        updateId: updateId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<int> createElement() {
    return _CommentCountProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is CommentCountProvider && other.updateId == updateId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, updateId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin CommentCountRef on AutoDisposeFutureProviderRef<int> {
  /// The parameter `updateId` of this provider.
  String get updateId;
}

class _CommentCountProviderElement extends AutoDisposeFutureProviderElement<int>
    with CommentCountRef {
  _CommentCountProviderElement(super.provider);

  @override
  String get updateId => (origin as CommentCountProvider).updateId;
}

String _$presetTemplatesHash() => r'b48c5b8ece70f0c20d4b8988759912e22a32d1c7';

/// Get all preset templates
///
/// Copied from [presetTemplates].
@ProviderFor(presetTemplates)
final presetTemplatesProvider =
    AutoDisposeProvider<List<UpdatePresetTemplate>>.internal(
  presetTemplates,
  name: r'presetTemplatesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$presetTemplatesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PresetTemplatesRef = AutoDisposeProviderRef<List<UpdatePresetTemplate>>;
String _$presetsByCategoryHash() => r'cab288282a10bf963bcf9972de1f00a2635f3311';

/// Get presets by category
///
/// Copied from [presetsByCategory].
@ProviderFor(presetsByCategory)
const presetsByCategoryProvider = PresetsByCategoryFamily();

/// Get presets by category
///
/// Copied from [presetsByCategory].
class PresetsByCategoryFamily extends Family<List<UpdatePresetTemplate>> {
  /// Get presets by category
  ///
  /// Copied from [presetsByCategory].
  const PresetsByCategoryFamily();

  /// Get presets by category
  ///
  /// Copied from [presetsByCategory].
  PresetsByCategoryProvider call(
    PresetCategory category,
  ) {
    return PresetsByCategoryProvider(
      category,
    );
  }

  @override
  PresetsByCategoryProvider getProviderOverride(
    covariant PresetsByCategoryProvider provider,
  ) {
    return call(
      provider.category,
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
  String? get name => r'presetsByCategoryProvider';
}

/// Get presets by category
///
/// Copied from [presetsByCategory].
class PresetsByCategoryProvider
    extends AutoDisposeProvider<List<UpdatePresetTemplate>> {
  /// Get presets by category
  ///
  /// Copied from [presetsByCategory].
  PresetsByCategoryProvider(
    PresetCategory category,
  ) : this._internal(
          (ref) => presetsByCategory(
            ref as PresetsByCategoryRef,
            category,
          ),
          from: presetsByCategoryProvider,
          name: r'presetsByCategoryProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$presetsByCategoryHash,
          dependencies: PresetsByCategoryFamily._dependencies,
          allTransitiveDependencies:
              PresetsByCategoryFamily._allTransitiveDependencies,
          category: category,
        );

  PresetsByCategoryProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.category,
  }) : super.internal();

  final PresetCategory category;

  @override
  Override overrideWith(
    List<UpdatePresetTemplate> Function(PresetsByCategoryRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: PresetsByCategoryProvider._internal(
        (ref) => create(ref as PresetsByCategoryRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        category: category,
      ),
    );
  }

  @override
  AutoDisposeProviderElement<List<UpdatePresetTemplate>> createElement() {
    return _PresetsByCategoryProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PresetsByCategoryProvider && other.category == category;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, category.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin PresetsByCategoryRef
    on AutoDisposeProviderRef<List<UpdatePresetTemplate>> {
  /// The parameter `category` of this provider.
  PresetCategory get category;
}

class _PresetsByCategoryProviderElement
    extends AutoDisposeProviderElement<List<UpdatePresetTemplate>>
    with PresetsByCategoryRef {
  _PresetsByCategoryProviderElement(super.provider);

  @override
  PresetCategory get category => (origin as PresetsByCategoryProvider).category;
}

String _$presetCategoriesHash() => r'7f7551624d3c07b5df8ec428f289a6c78090dfdf';

/// Get all preset categories
///
/// Copied from [presetCategories].
@ProviderFor(presetCategories)
final presetCategoriesProvider =
    AutoDisposeProvider<List<PresetCategory>>.internal(
  presetCategories,
  name: r'presetCategoriesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$presetCategoriesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PresetCategoriesRef = AutoDisposeProviderRef<List<PresetCategory>>;
String _$updateSuggestionsHash() => r'8644a1c1e313e5861133e5418a3b9ffbc1228ba7';

/// Get suggested updates for current user in a group
///
/// Copied from [updateSuggestions].
@ProviderFor(updateSuggestions)
const updateSuggestionsProvider = UpdateSuggestionsFamily();

/// Get suggested updates for current user in a group
///
/// Copied from [updateSuggestions].
class UpdateSuggestionsFamily
    extends Family<AsyncValue<List<UpdateSuggestion>>> {
  /// Get suggested updates for current user in a group
  ///
  /// Copied from [updateSuggestions].
  const UpdateSuggestionsFamily();

  /// Get suggested updates for current user in a group
  ///
  /// Copied from [updateSuggestions].
  UpdateSuggestionsProvider call(
    String groupId,
  ) {
    return UpdateSuggestionsProvider(
      groupId,
    );
  }

  @override
  UpdateSuggestionsProvider getProviderOverride(
    covariant UpdateSuggestionsProvider provider,
  ) {
    return call(
      provider.groupId,
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
  String? get name => r'updateSuggestionsProvider';
}

/// Get suggested updates for current user in a group
///
/// Copied from [updateSuggestions].
class UpdateSuggestionsProvider
    extends AutoDisposeFutureProvider<List<UpdateSuggestion>> {
  /// Get suggested updates for current user in a group
  ///
  /// Copied from [updateSuggestions].
  UpdateSuggestionsProvider(
    String groupId,
  ) : this._internal(
          (ref) => updateSuggestions(
            ref as UpdateSuggestionsRef,
            groupId,
          ),
          from: updateSuggestionsProvider,
          name: r'updateSuggestionsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$updateSuggestionsHash,
          dependencies: UpdateSuggestionsFamily._dependencies,
          allTransitiveDependencies:
              UpdateSuggestionsFamily._allTransitiveDependencies,
          groupId: groupId,
        );

  UpdateSuggestionsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.groupId,
  }) : super.internal();

  final String groupId;

  @override
  Override overrideWith(
    FutureOr<List<UpdateSuggestion>> Function(UpdateSuggestionsRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: UpdateSuggestionsProvider._internal(
        (ref) => create(ref as UpdateSuggestionsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        groupId: groupId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<UpdateSuggestion>> createElement() {
    return _UpdateSuggestionsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is UpdateSuggestionsProvider && other.groupId == groupId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, groupId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin UpdateSuggestionsRef
    on AutoDisposeFutureProviderRef<List<UpdateSuggestion>> {
  /// The parameter `groupId` of this provider.
  String get groupId;
}

class _UpdateSuggestionsProviderElement
    extends AutoDisposeFutureProviderElement<List<UpdateSuggestion>>
    with UpdateSuggestionsRef {
  _UpdateSuggestionsProviderElement(super.provider);

  @override
  String get groupId => (origin as UpdateSuggestionsProvider).groupId;
}

String _$postUpdateControllerHash() =>
    r'ff8ebed4d1f59d7a7dabadb64c1ffbdb7c87775b';

/// Controller for posting updates
///
/// Copied from [PostUpdateController].
@ProviderFor(PostUpdateController)
final postUpdateControllerProvider =
    AutoDisposeNotifierProvider<PostUpdateController, bool>.internal(
  PostUpdateController.new,
  name: r'postUpdateControllerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$postUpdateControllerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$PostUpdateController = AutoDisposeNotifier<bool>;
String _$postCommentControllerHash() =>
    r'122dfb561e217d4e2895e1107467d4330e2e99a8';

/// Controller for posting comments
///
/// Copied from [PostCommentController].
@ProviderFor(PostCommentController)
final postCommentControllerProvider =
    AutoDisposeNotifierProvider<PostCommentController, bool>.internal(
  PostCommentController.new,
  name: r'postCommentControllerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$postCommentControllerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$PostCommentController = AutoDisposeNotifier<bool>;
String _$deleteCommentControllerHash() =>
    r'd8162440796e5bc7193e75c32dadf937b23ec336';

/// Controller for deleting comments
///
/// Copied from [DeleteCommentController].
@ProviderFor(DeleteCommentController)
final deleteCommentControllerProvider =
    AutoDisposeNotifierProvider<DeleteCommentController, bool>.internal(
  DeleteCommentController.new,
  name: r'deleteCommentControllerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$deleteCommentControllerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$DeleteCommentController = AutoDisposeNotifier<bool>;
String _$updateReactionsControllerHash() =>
    r'3ca12b7cad85269c3876de9227a2e235b18d6caf';

/// Controller for update reactions
///
/// Copied from [UpdateReactionsController].
@ProviderFor(UpdateReactionsController)
final updateReactionsControllerProvider =
    AutoDisposeNotifierProvider<UpdateReactionsController, bool>.internal(
  UpdateReactionsController.new,
  name: r'updateReactionsControllerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$updateReactionsControllerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$UpdateReactionsController = AutoDisposeNotifier<bool>;
String _$commentsControllerHash() =>
    r'591d76c5bfce4a153bee9ea75d124d308b0b6e4e';

/// Controller for comments
///
/// Copied from [CommentsController].
@ProviderFor(CommentsController)
final commentsControllerProvider =
    AutoDisposeNotifierProvider<CommentsController, bool>.internal(
  CommentsController.new,
  name: r'commentsControllerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$commentsControllerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$CommentsController = AutoDisposeNotifier<bool>;
String _$commentReactionsControllerHash() =>
    r'10ae11c67445dbf2c5c7d037f9a884a59a5305c2';

/// Controller for comment reactions
///
/// Copied from [CommentReactionsController].
@ProviderFor(CommentReactionsController)
final commentReactionsControllerProvider =
    AutoDisposeNotifierProvider<CommentReactionsController, bool>.internal(
  CommentReactionsController.new,
  name: r'commentReactionsControllerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$commentReactionsControllerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$CommentReactionsController = AutoDisposeNotifier<bool>;
String _$updateManagementControllerHash() =>
    r'45ef25831ea1486cb1e71d7bc2a147c417a293ab';

/// Controller for update management (edit/delete)
///
/// Copied from [UpdateManagementController].
@ProviderFor(UpdateManagementController)
final updateManagementControllerProvider =
    AutoDisposeNotifierProvider<UpdateManagementController, bool>.internal(
  UpdateManagementController.new,
  name: r'updateManagementControllerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$updateManagementControllerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$UpdateManagementController = AutoDisposeNotifier<bool>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
