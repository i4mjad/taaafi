// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'groups_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$currentGroupMembershipHash() =>
    r'885ac9960c583eb4949e130d7bd8208acd5110fa';

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

/// Provider for current user's group membership
///
/// Copied from [currentGroupMembership].
@ProviderFor(currentGroupMembership)
const currentGroupMembershipProvider = CurrentGroupMembershipFamily();

/// Provider for current user's group membership
///
/// Copied from [currentGroupMembership].
class CurrentGroupMembershipFamily
    extends Family<AsyncValue<GroupMembershipEntity?>> {
  /// Provider for current user's group membership
  ///
  /// Copied from [currentGroupMembership].
  const CurrentGroupMembershipFamily();

  /// Provider for current user's group membership
  ///
  /// Copied from [currentGroupMembership].
  CurrentGroupMembershipProvider call(
    String cpId,
  ) {
    return CurrentGroupMembershipProvider(
      cpId,
    );
  }

  @override
  CurrentGroupMembershipProvider getProviderOverride(
    covariant CurrentGroupMembershipProvider provider,
  ) {
    return call(
      provider.cpId,
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
  String? get name => r'currentGroupMembershipProvider';
}

/// Provider for current user's group membership
///
/// Copied from [currentGroupMembership].
class CurrentGroupMembershipProvider
    extends AutoDisposeFutureProvider<GroupMembershipEntity?> {
  /// Provider for current user's group membership
  ///
  /// Copied from [currentGroupMembership].
  CurrentGroupMembershipProvider(
    String cpId,
  ) : this._internal(
          (ref) => currentGroupMembership(
            ref as CurrentGroupMembershipRef,
            cpId,
          ),
          from: currentGroupMembershipProvider,
          name: r'currentGroupMembershipProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$currentGroupMembershipHash,
          dependencies: CurrentGroupMembershipFamily._dependencies,
          allTransitiveDependencies:
              CurrentGroupMembershipFamily._allTransitiveDependencies,
          cpId: cpId,
        );

  CurrentGroupMembershipProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.cpId,
  }) : super.internal();

  final String cpId;

  @override
  Override overrideWith(
    FutureOr<GroupMembershipEntity?> Function(
            CurrentGroupMembershipRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: CurrentGroupMembershipProvider._internal(
        (ref) => create(ref as CurrentGroupMembershipRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        cpId: cpId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<GroupMembershipEntity?> createElement() {
    return _CurrentGroupMembershipProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is CurrentGroupMembershipProvider && other.cpId == cpId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, cpId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin CurrentGroupMembershipRef
    on AutoDisposeFutureProviderRef<GroupMembershipEntity?> {
  /// The parameter `cpId` of this provider.
  String get cpId;
}

class _CurrentGroupMembershipProviderElement
    extends AutoDisposeFutureProviderElement<GroupMembershipEntity?>
    with CurrentGroupMembershipRef {
  _CurrentGroupMembershipProviderElement(super.provider);

  @override
  String get cpId => (origin as CurrentGroupMembershipProvider).cpId;
}

String _$publicGroupsHash() => r'758ff4f57e5243f76e2f8b37106d399afd261ce6';

/// Provider for public groups stream
///
/// Copied from [publicGroups].
@ProviderFor(publicGroups)
final publicGroupsProvider =
    AutoDisposeStreamProvider<List<GroupEntity>>.internal(
  publicGroups,
  name: r'publicGroupsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$publicGroupsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PublicGroupsRef = AutoDisposeStreamProviderRef<List<GroupEntity>>;
String _$canJoinGroupHash() => r'f9f766c1da606912bea87727067b64584f006d4a';

/// Provider to check if user can join groups
///
/// Copied from [canJoinGroup].
@ProviderFor(canJoinGroup)
const canJoinGroupProvider = CanJoinGroupFamily();

/// Provider to check if user can join groups
///
/// Copied from [canJoinGroup].
class CanJoinGroupFamily extends Family<AsyncValue<bool>> {
  /// Provider to check if user can join groups
  ///
  /// Copied from [canJoinGroup].
  const CanJoinGroupFamily();

  /// Provider to check if user can join groups
  ///
  /// Copied from [canJoinGroup].
  CanJoinGroupProvider call(
    String cpId,
  ) {
    return CanJoinGroupProvider(
      cpId,
    );
  }

  @override
  CanJoinGroupProvider getProviderOverride(
    covariant CanJoinGroupProvider provider,
  ) {
    return call(
      provider.cpId,
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
  String? get name => r'canJoinGroupProvider';
}

/// Provider to check if user can join groups
///
/// Copied from [canJoinGroup].
class CanJoinGroupProvider extends AutoDisposeFutureProvider<bool> {
  /// Provider to check if user can join groups
  ///
  /// Copied from [canJoinGroup].
  CanJoinGroupProvider(
    String cpId,
  ) : this._internal(
          (ref) => canJoinGroup(
            ref as CanJoinGroupRef,
            cpId,
          ),
          from: canJoinGroupProvider,
          name: r'canJoinGroupProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$canJoinGroupHash,
          dependencies: CanJoinGroupFamily._dependencies,
          allTransitiveDependencies:
              CanJoinGroupFamily._allTransitiveDependencies,
          cpId: cpId,
        );

  CanJoinGroupProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.cpId,
  }) : super.internal();

  final String cpId;

  @override
  Override overrideWith(
    FutureOr<bool> Function(CanJoinGroupRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: CanJoinGroupProvider._internal(
        (ref) => create(ref as CanJoinGroupRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        cpId: cpId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<bool> createElement() {
    return _CanJoinGroupProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is CanJoinGroupProvider && other.cpId == cpId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, cpId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin CanJoinGroupRef on AutoDisposeFutureProviderRef<bool> {
  /// The parameter `cpId` of this provider.
  String get cpId;
}

class _CanJoinGroupProviderElement
    extends AutoDisposeFutureProviderElement<bool> with CanJoinGroupRef {
  _CanJoinGroupProviderElement(super.provider);

  @override
  String get cpId => (origin as CanJoinGroupProvider).cpId;
}

String _$nextJoinAllowedAtHash() => r'deb6ebf1bc373029b7f90778d1364286227987c5';

/// Provider for next join allowed time
///
/// Copied from [nextJoinAllowedAt].
@ProviderFor(nextJoinAllowedAt)
const nextJoinAllowedAtProvider = NextJoinAllowedAtFamily();

/// Provider for next join allowed time
///
/// Copied from [nextJoinAllowedAt].
class NextJoinAllowedAtFamily extends Family<AsyncValue<DateTime?>> {
  /// Provider for next join allowed time
  ///
  /// Copied from [nextJoinAllowedAt].
  const NextJoinAllowedAtFamily();

  /// Provider for next join allowed time
  ///
  /// Copied from [nextJoinAllowedAt].
  NextJoinAllowedAtProvider call(
    String cpId,
  ) {
    return NextJoinAllowedAtProvider(
      cpId,
    );
  }

  @override
  NextJoinAllowedAtProvider getProviderOverride(
    covariant NextJoinAllowedAtProvider provider,
  ) {
    return call(
      provider.cpId,
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
  String? get name => r'nextJoinAllowedAtProvider';
}

/// Provider for next join allowed time
///
/// Copied from [nextJoinAllowedAt].
class NextJoinAllowedAtProvider extends AutoDisposeFutureProvider<DateTime?> {
  /// Provider for next join allowed time
  ///
  /// Copied from [nextJoinAllowedAt].
  NextJoinAllowedAtProvider(
    String cpId,
  ) : this._internal(
          (ref) => nextJoinAllowedAt(
            ref as NextJoinAllowedAtRef,
            cpId,
          ),
          from: nextJoinAllowedAtProvider,
          name: r'nextJoinAllowedAtProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$nextJoinAllowedAtHash,
          dependencies: NextJoinAllowedAtFamily._dependencies,
          allTransitiveDependencies:
              NextJoinAllowedAtFamily._allTransitiveDependencies,
          cpId: cpId,
        );

  NextJoinAllowedAtProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.cpId,
  }) : super.internal();

  final String cpId;

  @override
  Override overrideWith(
    FutureOr<DateTime?> Function(NextJoinAllowedAtRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: NextJoinAllowedAtProvider._internal(
        (ref) => create(ref as NextJoinAllowedAtRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        cpId: cpId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<DateTime?> createElement() {
    return _NextJoinAllowedAtProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is NextJoinAllowedAtProvider && other.cpId == cpId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, cpId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin NextJoinAllowedAtRef on AutoDisposeFutureProviderRef<DateTime?> {
  /// The parameter `cpId` of this provider.
  String get cpId;
}

class _NextJoinAllowedAtProviderElement
    extends AutoDisposeFutureProviderElement<DateTime?>
    with NextJoinAllowedAtRef {
  _NextJoinAllowedAtProviderElement(super.provider);

  @override
  String get cpId => (origin as NextJoinAllowedAtProvider).cpId;
}

String _$groupsControllerHash() => r'cade3101a9efecea7fc1506fdbf154c72ed6940b';

/// Controller for handling group actions (join, create, leave)
///
/// Copied from [GroupsController].
@ProviderFor(GroupsController)
final groupsControllerProvider =
    AutoDisposeAsyncNotifierProvider<GroupsController, void>.internal(
  GroupsController.new,
  name: r'groupsControllerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$groupsControllerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$GroupsController = AutoDisposeAsyncNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
