// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'challenges_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$challengesRepositoryHash() =>
    r'59c82d0d752c0605a13c0ad0c8e7a99607a276ee';

/// See also [challengesRepository].
@ProviderFor(challengesRepository)
final challengesRepositoryProvider =
    AutoDisposeProvider<ChallengesRepository>.internal(
  challengesRepository,
  name: r'challengesRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$challengesRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ChallengesRepositoryRef = AutoDisposeProviderRef<ChallengesRepository>;
String _$challengesServiceHash() => r'd8aeef7842745f66c23f6095f8f5e680e728946d';

/// See also [challengesService].
@ProviderFor(challengesService)
final challengesServiceProvider =
    AutoDisposeProvider<ChallengesService>.internal(
  challengesService,
  name: r'challengesServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$challengesServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ChallengesServiceRef = AutoDisposeProviderRef<ChallengesService>;
String _$challengeProgressTrackerServiceHash() =>
    r'ef4e2fa38e14f3e7e71aaf3e1e3379cefacc131b';

/// See also [challengeProgressTrackerService].
@ProviderFor(challengeProgressTrackerService)
final challengeProgressTrackerServiceProvider =
    AutoDisposeProvider<ChallengeProgressTrackerService>.internal(
  challengeProgressTrackerService,
  name: r'challengeProgressTrackerServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$challengeProgressTrackerServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ChallengeProgressTrackerServiceRef
    = AutoDisposeProviderRef<ChallengeProgressTrackerService>;
String _$challengeNotificationServiceHash() =>
    r'cfc62d16a4894731ffec7152944e0752aacda2a5';

/// See also [challengeNotificationService].
@ProviderFor(challengeNotificationService)
final challengeNotificationServiceProvider =
    AutoDisposeProvider<ChallengeNotificationService>.internal(
  challengeNotificationService,
  name: r'challengeNotificationServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$challengeNotificationServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ChallengeNotificationServiceRef
    = AutoDisposeProviderRef<ChallengeNotificationService>;
String _$groupChallengesHash() => r'c2593aba8337836ba8ca3fff5999ee1b1df86c34';

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

/// Get all challenges for a group
///
/// Copied from [groupChallenges].
@ProviderFor(groupChallenges)
const groupChallengesProvider = GroupChallengesFamily();

/// Get all challenges for a group
///
/// Copied from [groupChallenges].
class GroupChallengesFamily extends Family<AsyncValue<List<ChallengeEntity>>> {
  /// Get all challenges for a group
  ///
  /// Copied from [groupChallenges].
  const GroupChallengesFamily();

  /// Get all challenges for a group
  ///
  /// Copied from [groupChallenges].
  GroupChallengesProvider call(
    String groupId,
  ) {
    return GroupChallengesProvider(
      groupId,
    );
  }

  @override
  GroupChallengesProvider getProviderOverride(
    covariant GroupChallengesProvider provider,
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
  String? get name => r'groupChallengesProvider';
}

/// Get all challenges for a group
///
/// Copied from [groupChallenges].
class GroupChallengesProvider
    extends AutoDisposeFutureProvider<List<ChallengeEntity>> {
  /// Get all challenges for a group
  ///
  /// Copied from [groupChallenges].
  GroupChallengesProvider(
    String groupId,
  ) : this._internal(
          (ref) => groupChallenges(
            ref as GroupChallengesRef,
            groupId,
          ),
          from: groupChallengesProvider,
          name: r'groupChallengesProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$groupChallengesHash,
          dependencies: GroupChallengesFamily._dependencies,
          allTransitiveDependencies:
              GroupChallengesFamily._allTransitiveDependencies,
          groupId: groupId,
        );

  GroupChallengesProvider._internal(
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
    FutureOr<List<ChallengeEntity>> Function(GroupChallengesRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: GroupChallengesProvider._internal(
        (ref) => create(ref as GroupChallengesRef),
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
  AutoDisposeFutureProviderElement<List<ChallengeEntity>> createElement() {
    return _GroupChallengesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is GroupChallengesProvider && other.groupId == groupId;
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
mixin GroupChallengesRef
    on AutoDisposeFutureProviderRef<List<ChallengeEntity>> {
  /// The parameter `groupId` of this provider.
  String get groupId;
}

class _GroupChallengesProviderElement
    extends AutoDisposeFutureProviderElement<List<ChallengeEntity>>
    with GroupChallengesRef {
  _GroupChallengesProviderElement(super.provider);

  @override
  String get groupId => (origin as GroupChallengesProvider).groupId;
}

String _$activeChallengesHash() => r'984d927280bb39ad24039cf8b818598ee79b7050';

/// Get active challenges for a group
///
/// Copied from [activeChallenges].
@ProviderFor(activeChallenges)
const activeChallengesProvider = ActiveChallengesFamily();

/// Get active challenges for a group
///
/// Copied from [activeChallenges].
class ActiveChallengesFamily extends Family<AsyncValue<List<ChallengeEntity>>> {
  /// Get active challenges for a group
  ///
  /// Copied from [activeChallenges].
  const ActiveChallengesFamily();

  /// Get active challenges for a group
  ///
  /// Copied from [activeChallenges].
  ActiveChallengesProvider call(
    String groupId,
  ) {
    return ActiveChallengesProvider(
      groupId,
    );
  }

  @override
  ActiveChallengesProvider getProviderOverride(
    covariant ActiveChallengesProvider provider,
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
  String? get name => r'activeChallengesProvider';
}

/// Get active challenges for a group
///
/// Copied from [activeChallenges].
class ActiveChallengesProvider
    extends AutoDisposeFutureProvider<List<ChallengeEntity>> {
  /// Get active challenges for a group
  ///
  /// Copied from [activeChallenges].
  ActiveChallengesProvider(
    String groupId,
  ) : this._internal(
          (ref) => activeChallenges(
            ref as ActiveChallengesRef,
            groupId,
          ),
          from: activeChallengesProvider,
          name: r'activeChallengesProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$activeChallengesHash,
          dependencies: ActiveChallengesFamily._dependencies,
          allTransitiveDependencies:
              ActiveChallengesFamily._allTransitiveDependencies,
          groupId: groupId,
        );

  ActiveChallengesProvider._internal(
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
    FutureOr<List<ChallengeEntity>> Function(ActiveChallengesRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ActiveChallengesProvider._internal(
        (ref) => create(ref as ActiveChallengesRef),
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
  AutoDisposeFutureProviderElement<List<ChallengeEntity>> createElement() {
    return _ActiveChallengesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ActiveChallengesProvider && other.groupId == groupId;
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
mixin ActiveChallengesRef
    on AutoDisposeFutureProviderRef<List<ChallengeEntity>> {
  /// The parameter `groupId` of this provider.
  String get groupId;
}

class _ActiveChallengesProviderElement
    extends AutoDisposeFutureProviderElement<List<ChallengeEntity>>
    with ActiveChallengesRef {
  _ActiveChallengesProviderElement(super.provider);

  @override
  String get groupId => (origin as ActiveChallengesProvider).groupId;
}

String _$completedChallengesHash() =>
    r'56212f0a1b008a6e2f4adf11bbfc7a47b3568b31';

/// Get completed challenges for a group
///
/// Copied from [completedChallenges].
@ProviderFor(completedChallenges)
const completedChallengesProvider = CompletedChallengesFamily();

/// Get completed challenges for a group
///
/// Copied from [completedChallenges].
class CompletedChallengesFamily
    extends Family<AsyncValue<List<ChallengeEntity>>> {
  /// Get completed challenges for a group
  ///
  /// Copied from [completedChallenges].
  const CompletedChallengesFamily();

  /// Get completed challenges for a group
  ///
  /// Copied from [completedChallenges].
  CompletedChallengesProvider call(
    String groupId,
  ) {
    return CompletedChallengesProvider(
      groupId,
    );
  }

  @override
  CompletedChallengesProvider getProviderOverride(
    covariant CompletedChallengesProvider provider,
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
  String? get name => r'completedChallengesProvider';
}

/// Get completed challenges for a group
///
/// Copied from [completedChallenges].
class CompletedChallengesProvider
    extends AutoDisposeFutureProvider<List<ChallengeEntity>> {
  /// Get completed challenges for a group
  ///
  /// Copied from [completedChallenges].
  CompletedChallengesProvider(
    String groupId,
  ) : this._internal(
          (ref) => completedChallenges(
            ref as CompletedChallengesRef,
            groupId,
          ),
          from: completedChallengesProvider,
          name: r'completedChallengesProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$completedChallengesHash,
          dependencies: CompletedChallengesFamily._dependencies,
          allTransitiveDependencies:
              CompletedChallengesFamily._allTransitiveDependencies,
          groupId: groupId,
        );

  CompletedChallengesProvider._internal(
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
    FutureOr<List<ChallengeEntity>> Function(CompletedChallengesRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: CompletedChallengesProvider._internal(
        (ref) => create(ref as CompletedChallengesRef),
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
  AutoDisposeFutureProviderElement<List<ChallengeEntity>> createElement() {
    return _CompletedChallengesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is CompletedChallengesProvider && other.groupId == groupId;
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
mixin CompletedChallengesRef
    on AutoDisposeFutureProviderRef<List<ChallengeEntity>> {
  /// The parameter `groupId` of this provider.
  String get groupId;
}

class _CompletedChallengesProviderElement
    extends AutoDisposeFutureProviderElement<List<ChallengeEntity>>
    with CompletedChallengesRef {
  _CompletedChallengesProviderElement(super.provider);

  @override
  String get groupId => (origin as CompletedChallengesProvider).groupId;
}

String _$challengeByIdHash() => r'03780b3adcf7ab4f6007f4fb9bab0288c0dc4750';

/// Get a single challenge by ID
///
/// Copied from [challengeById].
@ProviderFor(challengeById)
const challengeByIdProvider = ChallengeByIdFamily();

/// Get a single challenge by ID
///
/// Copied from [challengeById].
class ChallengeByIdFamily extends Family<AsyncValue<ChallengeEntity?>> {
  /// Get a single challenge by ID
  ///
  /// Copied from [challengeById].
  const ChallengeByIdFamily();

  /// Get a single challenge by ID
  ///
  /// Copied from [challengeById].
  ChallengeByIdProvider call(
    String challengeId,
  ) {
    return ChallengeByIdProvider(
      challengeId,
    );
  }

  @override
  ChallengeByIdProvider getProviderOverride(
    covariant ChallengeByIdProvider provider,
  ) {
    return call(
      provider.challengeId,
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
  String? get name => r'challengeByIdProvider';
}

/// Get a single challenge by ID
///
/// Copied from [challengeById].
class ChallengeByIdProvider
    extends AutoDisposeFutureProvider<ChallengeEntity?> {
  /// Get a single challenge by ID
  ///
  /// Copied from [challengeById].
  ChallengeByIdProvider(
    String challengeId,
  ) : this._internal(
          (ref) => challengeById(
            ref as ChallengeByIdRef,
            challengeId,
          ),
          from: challengeByIdProvider,
          name: r'challengeByIdProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$challengeByIdHash,
          dependencies: ChallengeByIdFamily._dependencies,
          allTransitiveDependencies:
              ChallengeByIdFamily._allTransitiveDependencies,
          challengeId: challengeId,
        );

  ChallengeByIdProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.challengeId,
  }) : super.internal();

  final String challengeId;

  @override
  Override overrideWith(
    FutureOr<ChallengeEntity?> Function(ChallengeByIdRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ChallengeByIdProvider._internal(
        (ref) => create(ref as ChallengeByIdRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        challengeId: challengeId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<ChallengeEntity?> createElement() {
    return _ChallengeByIdProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ChallengeByIdProvider && other.challengeId == challengeId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, challengeId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ChallengeByIdRef on AutoDisposeFutureProviderRef<ChallengeEntity?> {
  /// The parameter `challengeId` of this provider.
  String get challengeId;
}

class _ChallengeByIdProviderElement
    extends AutoDisposeFutureProviderElement<ChallengeEntity?>
    with ChallengeByIdRef {
  _ChallengeByIdProviderElement(super.provider);

  @override
  String get challengeId => (origin as ChallengeByIdProvider).challengeId;
}

String _$userChallengeParticipationHash() =>
    r'70e6782902cd76e639556e4c28976cc468d1d552';

/// Get user's participation in a specific challenge
///
/// Copied from [userChallengeParticipation].
@ProviderFor(userChallengeParticipation)
const userChallengeParticipationProvider = UserChallengeParticipationFamily();

/// Get user's participation in a specific challenge
///
/// Copied from [userChallengeParticipation].
class UserChallengeParticipationFamily
    extends Family<AsyncValue<ChallengeParticipationEntity?>> {
  /// Get user's participation in a specific challenge
  ///
  /// Copied from [userChallengeParticipation].
  const UserChallengeParticipationFamily();

  /// Get user's participation in a specific challenge
  ///
  /// Copied from [userChallengeParticipation].
  UserChallengeParticipationProvider call(
    String challengeId,
    String cpId,
  ) {
    return UserChallengeParticipationProvider(
      challengeId,
      cpId,
    );
  }

  @override
  UserChallengeParticipationProvider getProviderOverride(
    covariant UserChallengeParticipationProvider provider,
  ) {
    return call(
      provider.challengeId,
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
  String? get name => r'userChallengeParticipationProvider';
}

/// Get user's participation in a specific challenge
///
/// Copied from [userChallengeParticipation].
class UserChallengeParticipationProvider
    extends AutoDisposeFutureProvider<ChallengeParticipationEntity?> {
  /// Get user's participation in a specific challenge
  ///
  /// Copied from [userChallengeParticipation].
  UserChallengeParticipationProvider(
    String challengeId,
    String cpId,
  ) : this._internal(
          (ref) => userChallengeParticipation(
            ref as UserChallengeParticipationRef,
            challengeId,
            cpId,
          ),
          from: userChallengeParticipationProvider,
          name: r'userChallengeParticipationProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$userChallengeParticipationHash,
          dependencies: UserChallengeParticipationFamily._dependencies,
          allTransitiveDependencies:
              UserChallengeParticipationFamily._allTransitiveDependencies,
          challengeId: challengeId,
          cpId: cpId,
        );

  UserChallengeParticipationProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.challengeId,
    required this.cpId,
  }) : super.internal();

  final String challengeId;
  final String cpId;

  @override
  Override overrideWith(
    FutureOr<ChallengeParticipationEntity?> Function(
            UserChallengeParticipationRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: UserChallengeParticipationProvider._internal(
        (ref) => create(ref as UserChallengeParticipationRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        challengeId: challengeId,
        cpId: cpId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<ChallengeParticipationEntity?>
      createElement() {
    return _UserChallengeParticipationProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is UserChallengeParticipationProvider &&
        other.challengeId == challengeId &&
        other.cpId == cpId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, challengeId.hashCode);
    hash = _SystemHash.combine(hash, cpId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin UserChallengeParticipationRef
    on AutoDisposeFutureProviderRef<ChallengeParticipationEntity?> {
  /// The parameter `challengeId` of this provider.
  String get challengeId;

  /// The parameter `cpId` of this provider.
  String get cpId;
}

class _UserChallengeParticipationProviderElement
    extends AutoDisposeFutureProviderElement<ChallengeParticipationEntity?>
    with UserChallengeParticipationRef {
  _UserChallengeParticipationProviderElement(super.provider);

  @override
  String get challengeId =>
      (origin as UserChallengeParticipationProvider).challengeId;
  @override
  String get cpId => (origin as UserChallengeParticipationProvider).cpId;
}

String _$userActiveChallengesHash() =>
    r'1aad062410cc6a7a827952c5a69902adde2c4ec8';

/// Get user's active challenges
///
/// Copied from [userActiveChallenges].
@ProviderFor(userActiveChallenges)
const userActiveChallengesProvider = UserActiveChallengesFamily();

/// Get user's active challenges
///
/// Copied from [userActiveChallenges].
class UserActiveChallengesFamily
    extends Family<AsyncValue<List<ChallengeParticipationEntity>>> {
  /// Get user's active challenges
  ///
  /// Copied from [userActiveChallenges].
  const UserActiveChallengesFamily();

  /// Get user's active challenges
  ///
  /// Copied from [userActiveChallenges].
  UserActiveChallengesProvider call(
    String cpId,
  ) {
    return UserActiveChallengesProvider(
      cpId,
    );
  }

  @override
  UserActiveChallengesProvider getProviderOverride(
    covariant UserActiveChallengesProvider provider,
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
  String? get name => r'userActiveChallengesProvider';
}

/// Get user's active challenges
///
/// Copied from [userActiveChallenges].
class UserActiveChallengesProvider
    extends AutoDisposeFutureProvider<List<ChallengeParticipationEntity>> {
  /// Get user's active challenges
  ///
  /// Copied from [userActiveChallenges].
  UserActiveChallengesProvider(
    String cpId,
  ) : this._internal(
          (ref) => userActiveChallenges(
            ref as UserActiveChallengesRef,
            cpId,
          ),
          from: userActiveChallengesProvider,
          name: r'userActiveChallengesProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$userActiveChallengesHash,
          dependencies: UserActiveChallengesFamily._dependencies,
          allTransitiveDependencies:
              UserActiveChallengesFamily._allTransitiveDependencies,
          cpId: cpId,
        );

  UserActiveChallengesProvider._internal(
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
    FutureOr<List<ChallengeParticipationEntity>> Function(
            UserActiveChallengesRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: UserActiveChallengesProvider._internal(
        (ref) => create(ref as UserActiveChallengesRef),
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
  AutoDisposeFutureProviderElement<List<ChallengeParticipationEntity>>
      createElement() {
    return _UserActiveChallengesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is UserActiveChallengesProvider && other.cpId == cpId;
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
mixin UserActiveChallengesRef
    on AutoDisposeFutureProviderRef<List<ChallengeParticipationEntity>> {
  /// The parameter `cpId` of this provider.
  String get cpId;
}

class _UserActiveChallengesProviderElement
    extends AutoDisposeFutureProviderElement<List<ChallengeParticipationEntity>>
    with UserActiveChallengesRef {
  _UserActiveChallengesProviderElement(super.provider);

  @override
  String get cpId => (origin as UserActiveChallengesProvider).cpId;
}

String _$challengeLeaderboardHash() =>
    r'c0c9b2870e1fdce8ae4d6f384932e583c67ffd6c';

/// Get leaderboard for a challenge
///
/// Copied from [challengeLeaderboard].
@ProviderFor(challengeLeaderboard)
const challengeLeaderboardProvider = ChallengeLeaderboardFamily();

/// Get leaderboard for a challenge
///
/// Copied from [challengeLeaderboard].
class ChallengeLeaderboardFamily
    extends Family<AsyncValue<List<ChallengeParticipationEntity>>> {
  /// Get leaderboard for a challenge
  ///
  /// Copied from [challengeLeaderboard].
  const ChallengeLeaderboardFamily();

  /// Get leaderboard for a challenge
  ///
  /// Copied from [challengeLeaderboard].
  ChallengeLeaderboardProvider call(
    String challengeId, {
    int limit = 50,
  }) {
    return ChallengeLeaderboardProvider(
      challengeId,
      limit: limit,
    );
  }

  @override
  ChallengeLeaderboardProvider getProviderOverride(
    covariant ChallengeLeaderboardProvider provider,
  ) {
    return call(
      provider.challengeId,
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
  String? get name => r'challengeLeaderboardProvider';
}

/// Get leaderboard for a challenge
///
/// Copied from [challengeLeaderboard].
class ChallengeLeaderboardProvider
    extends AutoDisposeFutureProvider<List<ChallengeParticipationEntity>> {
  /// Get leaderboard for a challenge
  ///
  /// Copied from [challengeLeaderboard].
  ChallengeLeaderboardProvider(
    String challengeId, {
    int limit = 50,
  }) : this._internal(
          (ref) => challengeLeaderboard(
            ref as ChallengeLeaderboardRef,
            challengeId,
            limit: limit,
          ),
          from: challengeLeaderboardProvider,
          name: r'challengeLeaderboardProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$challengeLeaderboardHash,
          dependencies: ChallengeLeaderboardFamily._dependencies,
          allTransitiveDependencies:
              ChallengeLeaderboardFamily._allTransitiveDependencies,
          challengeId: challengeId,
          limit: limit,
        );

  ChallengeLeaderboardProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.challengeId,
    required this.limit,
  }) : super.internal();

  final String challengeId;
  final int limit;

  @override
  Override overrideWith(
    FutureOr<List<ChallengeParticipationEntity>> Function(
            ChallengeLeaderboardRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ChallengeLeaderboardProvider._internal(
        (ref) => create(ref as ChallengeLeaderboardRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        challengeId: challengeId,
        limit: limit,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<ChallengeParticipationEntity>>
      createElement() {
    return _ChallengeLeaderboardProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ChallengeLeaderboardProvider &&
        other.challengeId == challengeId &&
        other.limit == limit;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, challengeId.hashCode);
    hash = _SystemHash.combine(hash, limit.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ChallengeLeaderboardRef
    on AutoDisposeFutureProviderRef<List<ChallengeParticipationEntity>> {
  /// The parameter `challengeId` of this provider.
  String get challengeId;

  /// The parameter `limit` of this provider.
  int get limit;
}

class _ChallengeLeaderboardProviderElement
    extends AutoDisposeFutureProviderElement<List<ChallengeParticipationEntity>>
    with ChallengeLeaderboardRef {
  _ChallengeLeaderboardProviderElement(super.provider);

  @override
  String get challengeId =>
      (origin as ChallengeLeaderboardProvider).challengeId;
  @override
  int get limit => (origin as ChallengeLeaderboardProvider).limit;
}

String _$challengeStatsHash() => r'a2f0d5b2c7fb2d81f3187bf2e7754ac1a92fcf54';

/// Get challenge statistics
///
/// Copied from [challengeStats].
@ProviderFor(challengeStats)
const challengeStatsProvider = ChallengeStatsFamily();

/// Get challenge statistics
///
/// Copied from [challengeStats].
class ChallengeStatsFamily extends Family<AsyncValue<ChallengeStatsEntity>> {
  /// Get challenge statistics
  ///
  /// Copied from [challengeStats].
  const ChallengeStatsFamily();

  /// Get challenge statistics
  ///
  /// Copied from [challengeStats].
  ChallengeStatsProvider call(
    String challengeId,
  ) {
    return ChallengeStatsProvider(
      challengeId,
    );
  }

  @override
  ChallengeStatsProvider getProviderOverride(
    covariant ChallengeStatsProvider provider,
  ) {
    return call(
      provider.challengeId,
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
  String? get name => r'challengeStatsProvider';
}

/// Get challenge statistics
///
/// Copied from [challengeStats].
class ChallengeStatsProvider
    extends AutoDisposeFutureProvider<ChallengeStatsEntity> {
  /// Get challenge statistics
  ///
  /// Copied from [challengeStats].
  ChallengeStatsProvider(
    String challengeId,
  ) : this._internal(
          (ref) => challengeStats(
            ref as ChallengeStatsRef,
            challengeId,
          ),
          from: challengeStatsProvider,
          name: r'challengeStatsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$challengeStatsHash,
          dependencies: ChallengeStatsFamily._dependencies,
          allTransitiveDependencies:
              ChallengeStatsFamily._allTransitiveDependencies,
          challengeId: challengeId,
        );

  ChallengeStatsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.challengeId,
  }) : super.internal();

  final String challengeId;

  @override
  Override overrideWith(
    FutureOr<ChallengeStatsEntity> Function(ChallengeStatsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ChallengeStatsProvider._internal(
        (ref) => create(ref as ChallengeStatsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        challengeId: challengeId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<ChallengeStatsEntity> createElement() {
    return _ChallengeStatsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ChallengeStatsProvider && other.challengeId == challengeId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, challengeId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ChallengeStatsRef on AutoDisposeFutureProviderRef<ChallengeStatsEntity> {
  /// The parameter `challengeId` of this provider.
  String get challengeId;
}

class _ChallengeStatsProviderElement
    extends AutoDisposeFutureProviderElement<ChallengeStatsEntity>
    with ChallengeStatsRef {
  _ChallengeStatsProviderElement(super.provider);

  @override
  String get challengeId => (origin as ChallengeStatsProvider).challengeId;
}

String _$challengeUpdatesHash() => r'28517704c13c04634c9e704b6831eeac821a9766';

/// Get recent updates for a challenge
///
/// Copied from [challengeUpdates].
@ProviderFor(challengeUpdates)
const challengeUpdatesProvider = ChallengeUpdatesFamily();

/// Get recent updates for a challenge
///
/// Copied from [challengeUpdates].
class ChallengeUpdatesFamily
    extends Family<AsyncValue<List<ChallengeUpdateEntity>>> {
  /// Get recent updates for a challenge
  ///
  /// Copied from [challengeUpdates].
  const ChallengeUpdatesFamily();

  /// Get recent updates for a challenge
  ///
  /// Copied from [challengeUpdates].
  ChallengeUpdatesProvider call(
    String challengeId, {
    int limit = 20,
  }) {
    return ChallengeUpdatesProvider(
      challengeId,
      limit: limit,
    );
  }

  @override
  ChallengeUpdatesProvider getProviderOverride(
    covariant ChallengeUpdatesProvider provider,
  ) {
    return call(
      provider.challengeId,
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
  String? get name => r'challengeUpdatesProvider';
}

/// Get recent updates for a challenge
///
/// Copied from [challengeUpdates].
class ChallengeUpdatesProvider
    extends AutoDisposeFutureProvider<List<ChallengeUpdateEntity>> {
  /// Get recent updates for a challenge
  ///
  /// Copied from [challengeUpdates].
  ChallengeUpdatesProvider(
    String challengeId, {
    int limit = 20,
  }) : this._internal(
          (ref) => challengeUpdates(
            ref as ChallengeUpdatesRef,
            challengeId,
            limit: limit,
          ),
          from: challengeUpdatesProvider,
          name: r'challengeUpdatesProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$challengeUpdatesHash,
          dependencies: ChallengeUpdatesFamily._dependencies,
          allTransitiveDependencies:
              ChallengeUpdatesFamily._allTransitiveDependencies,
          challengeId: challengeId,
          limit: limit,
        );

  ChallengeUpdatesProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.challengeId,
    required this.limit,
  }) : super.internal();

  final String challengeId;
  final int limit;

  @override
  Override overrideWith(
    FutureOr<List<ChallengeUpdateEntity>> Function(ChallengeUpdatesRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ChallengeUpdatesProvider._internal(
        (ref) => create(ref as ChallengeUpdatesRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        challengeId: challengeId,
        limit: limit,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<ChallengeUpdateEntity>>
      createElement() {
    return _ChallengeUpdatesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ChallengeUpdatesProvider &&
        other.challengeId == challengeId &&
        other.limit == limit;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, challengeId.hashCode);
    hash = _SystemHash.combine(hash, limit.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ChallengeUpdatesRef
    on AutoDisposeFutureProviderRef<List<ChallengeUpdateEntity>> {
  /// The parameter `challengeId` of this provider.
  String get challengeId;

  /// The parameter `limit` of this provider.
  int get limit;
}

class _ChallengeUpdatesProviderElement
    extends AutoDisposeFutureProviderElement<List<ChallengeUpdateEntity>>
    with ChallengeUpdatesRef {
  _ChallengeUpdatesProviderElement(super.provider);

  @override
  String get challengeId => (origin as ChallengeUpdatesProvider).challengeId;
  @override
  int get limit => (origin as ChallengeUpdatesProvider).limit;
}

String _$challengeTaskInstancesHash() =>
    r'acdd944abd61274a4cadfb3976d0a7a4af5c3f7b';

/// Get task instances for a challenge (for the current user)
/// Loads challenge, user participation, and generates task instances
///
/// Copied from [challengeTaskInstances].
@ProviderFor(challengeTaskInstances)
const challengeTaskInstancesProvider = ChallengeTaskInstancesFamily();

/// Get task instances for a challenge (for the current user)
/// Loads challenge, user participation, and generates task instances
///
/// Copied from [challengeTaskInstances].
class ChallengeTaskInstancesFamily
    extends Family<AsyncValue<List<ChallengeTaskInstance>>> {
  /// Get task instances for a challenge (for the current user)
  /// Loads challenge, user participation, and generates task instances
  ///
  /// Copied from [challengeTaskInstances].
  const ChallengeTaskInstancesFamily();

  /// Get task instances for a challenge (for the current user)
  /// Loads challenge, user participation, and generates task instances
  ///
  /// Copied from [challengeTaskInstances].
  ChallengeTaskInstancesProvider call(
    String challengeId,
  ) {
    return ChallengeTaskInstancesProvider(
      challengeId,
    );
  }

  @override
  ChallengeTaskInstancesProvider getProviderOverride(
    covariant ChallengeTaskInstancesProvider provider,
  ) {
    return call(
      provider.challengeId,
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
  String? get name => r'challengeTaskInstancesProvider';
}

/// Get task instances for a challenge (for the current user)
/// Loads challenge, user participation, and generates task instances
///
/// Copied from [challengeTaskInstances].
class ChallengeTaskInstancesProvider
    extends AutoDisposeFutureProvider<List<ChallengeTaskInstance>> {
  /// Get task instances for a challenge (for the current user)
  /// Loads challenge, user participation, and generates task instances
  ///
  /// Copied from [challengeTaskInstances].
  ChallengeTaskInstancesProvider(
    String challengeId,
  ) : this._internal(
          (ref) => challengeTaskInstances(
            ref as ChallengeTaskInstancesRef,
            challengeId,
          ),
          from: challengeTaskInstancesProvider,
          name: r'challengeTaskInstancesProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$challengeTaskInstancesHash,
          dependencies: ChallengeTaskInstancesFamily._dependencies,
          allTransitiveDependencies:
              ChallengeTaskInstancesFamily._allTransitiveDependencies,
          challengeId: challengeId,
        );

  ChallengeTaskInstancesProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.challengeId,
  }) : super.internal();

  final String challengeId;

  @override
  Override overrideWith(
    FutureOr<List<ChallengeTaskInstance>> Function(
            ChallengeTaskInstancesRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ChallengeTaskInstancesProvider._internal(
        (ref) => create(ref as ChallengeTaskInstancesRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        challengeId: challengeId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<ChallengeTaskInstance>>
      createElement() {
    return _ChallengeTaskInstancesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ChallengeTaskInstancesProvider &&
        other.challengeId == challengeId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, challengeId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ChallengeTaskInstancesRef
    on AutoDisposeFutureProviderRef<List<ChallengeTaskInstance>> {
  /// The parameter `challengeId` of this provider.
  String get challengeId;
}

class _ChallengeTaskInstancesProviderElement
    extends AutoDisposeFutureProviderElement<List<ChallengeTaskInstance>>
    with ChallengeTaskInstancesRef {
  _ChallengeTaskInstancesProviderElement(super.provider);

  @override
  String get challengeId =>
      (origin as ChallengeTaskInstancesProvider).challengeId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
