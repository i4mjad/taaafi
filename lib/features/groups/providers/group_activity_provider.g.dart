// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_activity_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$groupActivityServiceHash() =>
    r'8d317a019c5a3b0edea6156014cc02b24dc89991';

/// See also [groupActivityService].
@ProviderFor(groupActivityService)
final groupActivityServiceProvider =
    AutoDisposeProvider<GroupActivityService>.internal(
  groupActivityService,
  name: r'groupActivityServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$groupActivityServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef GroupActivityServiceRef = AutoDisposeProviderRef<GroupActivityService>;
String _$groupMembersWithActivityHash() =>
    r'0cb5c47485c97ecade1352058ec602b63916ef98';

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

/// Provider for fetching members with activity data for a specific group
///
/// Copied from [groupMembersWithActivity].
@ProviderFor(groupMembersWithActivity)
const groupMembersWithActivityProvider = GroupMembersWithActivityFamily();

/// Provider for fetching members with activity data for a specific group
///
/// Copied from [groupMembersWithActivity].
class GroupMembersWithActivityFamily
    extends Family<AsyncValue<List<GroupMembershipEntity>>> {
  /// Provider for fetching members with activity data for a specific group
  ///
  /// Copied from [groupMembersWithActivity].
  const GroupMembersWithActivityFamily();

  /// Provider for fetching members with activity data for a specific group
  ///
  /// Copied from [groupMembersWithActivity].
  GroupMembersWithActivityProvider call(
    String groupId,
  ) {
    return GroupMembersWithActivityProvider(
      groupId,
    );
  }

  @override
  GroupMembersWithActivityProvider getProviderOverride(
    covariant GroupMembersWithActivityProvider provider,
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
  String? get name => r'groupMembersWithActivityProvider';
}

/// Provider for fetching members with activity data for a specific group
///
/// Copied from [groupMembersWithActivity].
class GroupMembersWithActivityProvider
    extends AutoDisposeFutureProvider<List<GroupMembershipEntity>> {
  /// Provider for fetching members with activity data for a specific group
  ///
  /// Copied from [groupMembersWithActivity].
  GroupMembersWithActivityProvider(
    String groupId,
  ) : this._internal(
          (ref) => groupMembersWithActivity(
            ref as GroupMembersWithActivityRef,
            groupId,
          ),
          from: groupMembersWithActivityProvider,
          name: r'groupMembersWithActivityProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$groupMembersWithActivityHash,
          dependencies: GroupMembersWithActivityFamily._dependencies,
          allTransitiveDependencies:
              GroupMembersWithActivityFamily._allTransitiveDependencies,
          groupId: groupId,
        );

  GroupMembersWithActivityProvider._internal(
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
    FutureOr<List<GroupMembershipEntity>> Function(
            GroupMembersWithActivityRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: GroupMembersWithActivityProvider._internal(
        (ref) => create(ref as GroupMembersWithActivityRef),
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
  AutoDisposeFutureProviderElement<List<GroupMembershipEntity>>
      createElement() {
    return _GroupMembersWithActivityProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is GroupMembersWithActivityProvider &&
        other.groupId == groupId;
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
mixin GroupMembersWithActivityRef
    on AutoDisposeFutureProviderRef<List<GroupMembershipEntity>> {
  /// The parameter `groupId` of this provider.
  String get groupId;
}

class _GroupMembersWithActivityProviderElement
    extends AutoDisposeFutureProviderElement<List<GroupMembershipEntity>>
    with GroupMembersWithActivityRef {
  _GroupMembersWithActivityProviderElement(super.provider);

  @override
  String get groupId => (origin as GroupMembersWithActivityProvider).groupId;
}

String _$inactiveGroupMembersHash() =>
    r'cf350c0ab4c923e5d2388ea2ceafe73f3e9c3f12';

/// Provider for fetching inactive members (not active for X days)
///
/// Copied from [inactiveGroupMembers].
@ProviderFor(inactiveGroupMembers)
const inactiveGroupMembersProvider = InactiveGroupMembersFamily();

/// Provider for fetching inactive members (not active for X days)
///
/// Copied from [inactiveGroupMembers].
class InactiveGroupMembersFamily
    extends Family<AsyncValue<List<GroupMembershipEntity>>> {
  /// Provider for fetching inactive members (not active for X days)
  ///
  /// Copied from [inactiveGroupMembers].
  const InactiveGroupMembersFamily();

  /// Provider for fetching inactive members (not active for X days)
  ///
  /// Copied from [inactiveGroupMembers].
  InactiveGroupMembersProvider call(
    String groupId, {
    int days = 7,
  }) {
    return InactiveGroupMembersProvider(
      groupId,
      days: days,
    );
  }

  @override
  InactiveGroupMembersProvider getProviderOverride(
    covariant InactiveGroupMembersProvider provider,
  ) {
    return call(
      provider.groupId,
      days: provider.days,
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
  String? get name => r'inactiveGroupMembersProvider';
}

/// Provider for fetching inactive members (not active for X days)
///
/// Copied from [inactiveGroupMembers].
class InactiveGroupMembersProvider
    extends AutoDisposeFutureProvider<List<GroupMembershipEntity>> {
  /// Provider for fetching inactive members (not active for X days)
  ///
  /// Copied from [inactiveGroupMembers].
  InactiveGroupMembersProvider(
    String groupId, {
    int days = 7,
  }) : this._internal(
          (ref) => inactiveGroupMembers(
            ref as InactiveGroupMembersRef,
            groupId,
            days: days,
          ),
          from: inactiveGroupMembersProvider,
          name: r'inactiveGroupMembersProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$inactiveGroupMembersHash,
          dependencies: InactiveGroupMembersFamily._dependencies,
          allTransitiveDependencies:
              InactiveGroupMembersFamily._allTransitiveDependencies,
          groupId: groupId,
          days: days,
        );

  InactiveGroupMembersProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.groupId,
    required this.days,
  }) : super.internal();

  final String groupId;
  final int days;

  @override
  Override overrideWith(
    FutureOr<List<GroupMembershipEntity>> Function(
            InactiveGroupMembersRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: InactiveGroupMembersProvider._internal(
        (ref) => create(ref as InactiveGroupMembersRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        groupId: groupId,
        days: days,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<GroupMembershipEntity>>
      createElement() {
    return _InactiveGroupMembersProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is InactiveGroupMembersProvider &&
        other.groupId == groupId &&
        other.days == days;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, groupId.hashCode);
    hash = _SystemHash.combine(hash, days.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin InactiveGroupMembersRef
    on AutoDisposeFutureProviderRef<List<GroupMembershipEntity>> {
  /// The parameter `groupId` of this provider.
  String get groupId;

  /// The parameter `days` of this provider.
  int get days;
}

class _InactiveGroupMembersProviderElement
    extends AutoDisposeFutureProviderElement<List<GroupMembershipEntity>>
    with InactiveGroupMembersRef {
  _InactiveGroupMembersProviderElement(super.provider);

  @override
  String get groupId => (origin as InactiveGroupMembersProvider).groupId;
  @override
  int get days => (origin as InactiveGroupMembersProvider).days;
}

String _$groupActivityStatsHash() =>
    r'ff149ce1358c0389c56ca0ebf8f64e47abb4c90c';

/// Provider for group activity statistics
///
/// Copied from [groupActivityStats].
@ProviderFor(groupActivityStats)
const groupActivityStatsProvider = GroupActivityStatsFamily();

/// Provider for group activity statistics
///
/// Copied from [groupActivityStats].
class GroupActivityStatsFamily extends Family<AsyncValue<GroupActivityStats>> {
  /// Provider for group activity statistics
  ///
  /// Copied from [groupActivityStats].
  const GroupActivityStatsFamily();

  /// Provider for group activity statistics
  ///
  /// Copied from [groupActivityStats].
  GroupActivityStatsProvider call(
    String groupId,
  ) {
    return GroupActivityStatsProvider(
      groupId,
    );
  }

  @override
  GroupActivityStatsProvider getProviderOverride(
    covariant GroupActivityStatsProvider provider,
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
  String? get name => r'groupActivityStatsProvider';
}

/// Provider for group activity statistics
///
/// Copied from [groupActivityStats].
class GroupActivityStatsProvider
    extends AutoDisposeFutureProvider<GroupActivityStats> {
  /// Provider for group activity statistics
  ///
  /// Copied from [groupActivityStats].
  GroupActivityStatsProvider(
    String groupId,
  ) : this._internal(
          (ref) => groupActivityStats(
            ref as GroupActivityStatsRef,
            groupId,
          ),
          from: groupActivityStatsProvider,
          name: r'groupActivityStatsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$groupActivityStatsHash,
          dependencies: GroupActivityStatsFamily._dependencies,
          allTransitiveDependencies:
              GroupActivityStatsFamily._allTransitiveDependencies,
          groupId: groupId,
        );

  GroupActivityStatsProvider._internal(
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
    FutureOr<GroupActivityStats> Function(GroupActivityStatsRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: GroupActivityStatsProvider._internal(
        (ref) => create(ref as GroupActivityStatsRef),
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
  AutoDisposeFutureProviderElement<GroupActivityStats> createElement() {
    return _GroupActivityStatsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is GroupActivityStatsProvider && other.groupId == groupId;
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
mixin GroupActivityStatsRef
    on AutoDisposeFutureProviderRef<GroupActivityStats> {
  /// The parameter `groupId` of this provider.
  String get groupId;
}

class _GroupActivityStatsProviderElement
    extends AutoDisposeFutureProviderElement<GroupActivityStats>
    with GroupActivityStatsRef {
  _GroupActivityStatsProviderElement(super.provider);

  @override
  String get groupId => (origin as GroupActivityStatsProvider).groupId;
}

String _$membersSortedByActivityHash() =>
    r'350cb06943a6e8100d9a7627f9c1eeeafb86d5f5';

/// Provider for members sorted by activity (most recent first)
///
/// Copied from [membersSortedByActivity].
@ProviderFor(membersSortedByActivity)
const membersSortedByActivityProvider = MembersSortedByActivityFamily();

/// Provider for members sorted by activity (most recent first)
///
/// Copied from [membersSortedByActivity].
class MembersSortedByActivityFamily
    extends Family<AsyncValue<List<GroupMembershipEntity>>> {
  /// Provider for members sorted by activity (most recent first)
  ///
  /// Copied from [membersSortedByActivity].
  const MembersSortedByActivityFamily();

  /// Provider for members sorted by activity (most recent first)
  ///
  /// Copied from [membersSortedByActivity].
  MembersSortedByActivityProvider call(
    String groupId,
  ) {
    return MembersSortedByActivityProvider(
      groupId,
    );
  }

  @override
  MembersSortedByActivityProvider getProviderOverride(
    covariant MembersSortedByActivityProvider provider,
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
  String? get name => r'membersSortedByActivityProvider';
}

/// Provider for members sorted by activity (most recent first)
///
/// Copied from [membersSortedByActivity].
class MembersSortedByActivityProvider
    extends AutoDisposeFutureProvider<List<GroupMembershipEntity>> {
  /// Provider for members sorted by activity (most recent first)
  ///
  /// Copied from [membersSortedByActivity].
  MembersSortedByActivityProvider(
    String groupId,
  ) : this._internal(
          (ref) => membersSortedByActivity(
            ref as MembersSortedByActivityRef,
            groupId,
          ),
          from: membersSortedByActivityProvider,
          name: r'membersSortedByActivityProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$membersSortedByActivityHash,
          dependencies: MembersSortedByActivityFamily._dependencies,
          allTransitiveDependencies:
              MembersSortedByActivityFamily._allTransitiveDependencies,
          groupId: groupId,
        );

  MembersSortedByActivityProvider._internal(
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
    FutureOr<List<GroupMembershipEntity>> Function(
            MembersSortedByActivityRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: MembersSortedByActivityProvider._internal(
        (ref) => create(ref as MembersSortedByActivityRef),
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
  AutoDisposeFutureProviderElement<List<GroupMembershipEntity>>
      createElement() {
    return _MembersSortedByActivityProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is MembersSortedByActivityProvider && other.groupId == groupId;
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
mixin MembersSortedByActivityRef
    on AutoDisposeFutureProviderRef<List<GroupMembershipEntity>> {
  /// The parameter `groupId` of this provider.
  String get groupId;
}

class _MembersSortedByActivityProviderElement
    extends AutoDisposeFutureProviderElement<List<GroupMembershipEntity>>
    with MembersSortedByActivityRef {
  _MembersSortedByActivityProviderElement(super.provider);

  @override
  String get groupId => (origin as MembersSortedByActivityProvider).groupId;
}

String _$membersSortedByEngagementHash() =>
    r'8bd72232c6733727f563e4cf45e4b6650df72f09';

/// Provider for members sorted by engagement score (highest first)
///
/// Copied from [membersSortedByEngagement].
@ProviderFor(membersSortedByEngagement)
const membersSortedByEngagementProvider = MembersSortedByEngagementFamily();

/// Provider for members sorted by engagement score (highest first)
///
/// Copied from [membersSortedByEngagement].
class MembersSortedByEngagementFamily
    extends Family<AsyncValue<List<GroupMembershipEntity>>> {
  /// Provider for members sorted by engagement score (highest first)
  ///
  /// Copied from [membersSortedByEngagement].
  const MembersSortedByEngagementFamily();

  /// Provider for members sorted by engagement score (highest first)
  ///
  /// Copied from [membersSortedByEngagement].
  MembersSortedByEngagementProvider call(
    String groupId,
  ) {
    return MembersSortedByEngagementProvider(
      groupId,
    );
  }

  @override
  MembersSortedByEngagementProvider getProviderOverride(
    covariant MembersSortedByEngagementProvider provider,
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
  String? get name => r'membersSortedByEngagementProvider';
}

/// Provider for members sorted by engagement score (highest first)
///
/// Copied from [membersSortedByEngagement].
class MembersSortedByEngagementProvider
    extends AutoDisposeFutureProvider<List<GroupMembershipEntity>> {
  /// Provider for members sorted by engagement score (highest first)
  ///
  /// Copied from [membersSortedByEngagement].
  MembersSortedByEngagementProvider(
    String groupId,
  ) : this._internal(
          (ref) => membersSortedByEngagement(
            ref as MembersSortedByEngagementRef,
            groupId,
          ),
          from: membersSortedByEngagementProvider,
          name: r'membersSortedByEngagementProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$membersSortedByEngagementHash,
          dependencies: MembersSortedByEngagementFamily._dependencies,
          allTransitiveDependencies:
              MembersSortedByEngagementFamily._allTransitiveDependencies,
          groupId: groupId,
        );

  MembersSortedByEngagementProvider._internal(
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
    FutureOr<List<GroupMembershipEntity>> Function(
            MembersSortedByEngagementRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: MembersSortedByEngagementProvider._internal(
        (ref) => create(ref as MembersSortedByEngagementRef),
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
  AutoDisposeFutureProviderElement<List<GroupMembershipEntity>>
      createElement() {
    return _MembersSortedByEngagementProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is MembersSortedByEngagementProvider &&
        other.groupId == groupId;
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
mixin MembersSortedByEngagementRef
    on AutoDisposeFutureProviderRef<List<GroupMembershipEntity>> {
  /// The parameter `groupId` of this provider.
  String get groupId;
}

class _MembersSortedByEngagementProviderElement
    extends AutoDisposeFutureProviderElement<List<GroupMembershipEntity>>
    with MembersSortedByEngagementRef {
  _MembersSortedByEngagementProviderElement(super.provider);

  @override
  String get groupId => (origin as MembersSortedByEngagementProvider).groupId;
}

String _$membersByEngagementLevelHash() =>
    r'728dc6b5346ca8fbe345a4a507325c6cd752d50e';

/// Provider for filtering members by engagement level
///
/// Copied from [membersByEngagementLevel].
@ProviderFor(membersByEngagementLevel)
const membersByEngagementLevelProvider = MembersByEngagementLevelFamily();

/// Provider for filtering members by engagement level
///
/// Copied from [membersByEngagementLevel].
class MembersByEngagementLevelFamily
    extends Family<AsyncValue<List<GroupMembershipEntity>>> {
  /// Provider for filtering members by engagement level
  ///
  /// Copied from [membersByEngagementLevel].
  const MembersByEngagementLevelFamily();

  /// Provider for filtering members by engagement level
  ///
  /// Copied from [membersByEngagementLevel].
  MembersByEngagementLevelProvider call(
    String groupId,
    String level,
  ) {
    return MembersByEngagementLevelProvider(
      groupId,
      level,
    );
  }

  @override
  MembersByEngagementLevelProvider getProviderOverride(
    covariant MembersByEngagementLevelProvider provider,
  ) {
    return call(
      provider.groupId,
      provider.level,
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
  String? get name => r'membersByEngagementLevelProvider';
}

/// Provider for filtering members by engagement level
///
/// Copied from [membersByEngagementLevel].
class MembersByEngagementLevelProvider
    extends AutoDisposeFutureProvider<List<GroupMembershipEntity>> {
  /// Provider for filtering members by engagement level
  ///
  /// Copied from [membersByEngagementLevel].
  MembersByEngagementLevelProvider(
    String groupId,
    String level,
  ) : this._internal(
          (ref) => membersByEngagementLevel(
            ref as MembersByEngagementLevelRef,
            groupId,
            level,
          ),
          from: membersByEngagementLevelProvider,
          name: r'membersByEngagementLevelProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$membersByEngagementLevelHash,
          dependencies: MembersByEngagementLevelFamily._dependencies,
          allTransitiveDependencies:
              MembersByEngagementLevelFamily._allTransitiveDependencies,
          groupId: groupId,
          level: level,
        );

  MembersByEngagementLevelProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.groupId,
    required this.level,
  }) : super.internal();

  final String groupId;
  final String level;

  @override
  Override overrideWith(
    FutureOr<List<GroupMembershipEntity>> Function(
            MembersByEngagementLevelRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: MembersByEngagementLevelProvider._internal(
        (ref) => create(ref as MembersByEngagementLevelRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        groupId: groupId,
        level: level,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<GroupMembershipEntity>>
      createElement() {
    return _MembersByEngagementLevelProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is MembersByEngagementLevelProvider &&
        other.groupId == groupId &&
        other.level == level;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, groupId.hashCode);
    hash = _SystemHash.combine(hash, level.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin MembersByEngagementLevelRef
    on AutoDisposeFutureProviderRef<List<GroupMembershipEntity>> {
  /// The parameter `groupId` of this provider.
  String get groupId;

  /// The parameter `level` of this provider.
  String get level;
}

class _MembersByEngagementLevelProviderElement
    extends AutoDisposeFutureProviderElement<List<GroupMembershipEntity>>
    with MembersByEngagementLevelRef {
  _MembersByEngagementLevelProviderElement(super.provider);

  @override
  String get groupId => (origin as MembersByEngagementLevelProvider).groupId;
  @override
  String get level => (origin as MembersByEngagementLevelProvider).level;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
