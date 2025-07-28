// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'messaging_groups_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$messagingGroupsRepositoryHash() =>
    r'f6a39c21d734838eeb487d5d38aae28134f26567';

/// See also [messagingGroupsRepository].
@ProviderFor(messagingGroupsRepository)
final messagingGroupsRepositoryProvider =
    AutoDisposeProvider<MessagingGroupsRepository>.internal(
  messagingGroupsRepository,
  name: r'messagingGroupsRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$messagingGroupsRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef MessagingGroupsRepositoryRef
    = AutoDisposeProviderRef<MessagingGroupsRepository>;
String _$messagingGroupsServiceHash() =>
    r'9846fa55a86c69151a89daba473c899124c719f9';

/// See also [messagingGroupsService].
@ProviderFor(messagingGroupsService)
final messagingGroupsServiceProvider =
    AutoDisposeProvider<MessagingGroupsService>.internal(
  messagingGroupsService,
  name: r'messagingGroupsServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$messagingGroupsServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef MessagingGroupsServiceRef
    = AutoDisposeProviderRef<MessagingGroupsService>;
String _$availableGroupsStreamHash() =>
    r'4b4d5f36d89a5f5ab6481419b6b14e12bf8f8c72';

/// See also [availableGroupsStream].
@ProviderFor(availableGroupsStream)
final availableGroupsStreamProvider =
    AutoDisposeStreamProvider<List<MessagingGroup>>.internal(
  availableGroupsStream,
  name: r'availableGroupsStreamProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$availableGroupsStreamHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AvailableGroupsStreamRef
    = AutoDisposeStreamProviderRef<List<MessagingGroup>>;
String _$userGroupMembershipsStreamHash() =>
    r'8510276dc50217049ed43b149502b17ef857ebe9';

/// See also [userGroupMembershipsStream].
@ProviderFor(userGroupMembershipsStream)
final userGroupMembershipsStreamProvider =
    AutoDisposeStreamProvider<UserGroupMemberships?>.internal(
  userGroupMembershipsStream,
  name: r'userGroupMembershipsStreamProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$userGroupMembershipsStreamHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef UserGroupMembershipsStreamRef
    = AutoDisposeStreamProviderRef<UserGroupMemberships?>;
String _$availableGroupsHash() => r'88fc77aee9c36ab26ef0a0b35ffa6722a95f4191';

/// See also [availableGroups].
@ProviderFor(availableGroups)
final availableGroupsProvider =
    AutoDisposeFutureProvider<List<MessagingGroup>>.internal(
  availableGroups,
  name: r'availableGroupsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$availableGroupsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AvailableGroupsRef = AutoDisposeFutureProviderRef<List<MessagingGroup>>;
String _$userGroupMembershipsHash() =>
    r'e39ea6a8cf8c819715dc73d79e9371b7a632162b';

/// See also [userGroupMemberships].
@ProviderFor(userGroupMemberships)
final userGroupMembershipsProvider =
    AutoDisposeFutureProvider<UserGroupMemberships?>.internal(
  userGroupMemberships,
  name: r'userGroupMembershipsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$userGroupMembershipsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef UserGroupMembershipsRef
    = AutoDisposeFutureProviderRef<UserGroupMemberships?>;
String _$subscribedTopicIdsHash() =>
    r'0d10547417e1433bca1f0b43b44e19fde9822b6a';

/// See also [subscribedTopicIds].
@ProviderFor(subscribedTopicIds)
final subscribedTopicIdsProvider =
    AutoDisposeFutureProvider<List<String>>.internal(
  subscribedTopicIds,
  name: r'subscribedTopicIdsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$subscribedTopicIdsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SubscribedTopicIdsRef = AutoDisposeFutureProviderRef<List<String>>;
String _$isSubscribedToGroupHash() =>
    r'8972c592d5cb992c5654aa17fae16777ac4d005d';

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

/// See also [isSubscribedToGroup].
@ProviderFor(isSubscribedToGroup)
const isSubscribedToGroupProvider = IsSubscribedToGroupFamily();

/// See also [isSubscribedToGroup].
class IsSubscribedToGroupFamily extends Family<AsyncValue<bool>> {
  /// See also [isSubscribedToGroup].
  const IsSubscribedToGroupFamily();

  /// See also [isSubscribedToGroup].
  IsSubscribedToGroupProvider call(
    String topicId,
  ) {
    return IsSubscribedToGroupProvider(
      topicId,
    );
  }

  @override
  IsSubscribedToGroupProvider getProviderOverride(
    covariant IsSubscribedToGroupProvider provider,
  ) {
    return call(
      provider.topicId,
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
  String? get name => r'isSubscribedToGroupProvider';
}

/// See also [isSubscribedToGroup].
class IsSubscribedToGroupProvider extends AutoDisposeFutureProvider<bool> {
  /// See also [isSubscribedToGroup].
  IsSubscribedToGroupProvider(
    String topicId,
  ) : this._internal(
          (ref) => isSubscribedToGroup(
            ref as IsSubscribedToGroupRef,
            topicId,
          ),
          from: isSubscribedToGroupProvider,
          name: r'isSubscribedToGroupProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$isSubscribedToGroupHash,
          dependencies: IsSubscribedToGroupFamily._dependencies,
          allTransitiveDependencies:
              IsSubscribedToGroupFamily._allTransitiveDependencies,
          topicId: topicId,
        );

  IsSubscribedToGroupProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.topicId,
  }) : super.internal();

  final String topicId;

  @override
  Override overrideWith(
    FutureOr<bool> Function(IsSubscribedToGroupRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: IsSubscribedToGroupProvider._internal(
        (ref) => create(ref as IsSubscribedToGroupRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        topicId: topicId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<bool> createElement() {
    return _IsSubscribedToGroupProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is IsSubscribedToGroupProvider && other.topicId == topicId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, topicId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin IsSubscribedToGroupRef on AutoDisposeFutureProviderRef<bool> {
  /// The parameter `topicId` of this provider.
  String get topicId;
}

class _IsSubscribedToGroupProviderElement
    extends AutoDisposeFutureProviderElement<bool> with IsSubscribedToGroupRef {
  _IsSubscribedToGroupProviderElement(super.provider);

  @override
  String get topicId => (origin as IsSubscribedToGroupProvider).topicId;
}

String _$canSubscribeToGroupHash() =>
    r'15a0bde8e09808729f2cb32ac568bf05574084cd';

/// See also [canSubscribeToGroup].
@ProviderFor(canSubscribeToGroup)
const canSubscribeToGroupProvider = CanSubscribeToGroupFamily();

/// See also [canSubscribeToGroup].
class CanSubscribeToGroupFamily extends Family<AsyncValue<bool>> {
  /// See also [canSubscribeToGroup].
  const CanSubscribeToGroupFamily();

  /// See also [canSubscribeToGroup].
  CanSubscribeToGroupProvider call(
    MessagingGroup group,
  ) {
    return CanSubscribeToGroupProvider(
      group,
    );
  }

  @override
  CanSubscribeToGroupProvider getProviderOverride(
    covariant CanSubscribeToGroupProvider provider,
  ) {
    return call(
      provider.group,
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
  String? get name => r'canSubscribeToGroupProvider';
}

/// See also [canSubscribeToGroup].
class CanSubscribeToGroupProvider extends AutoDisposeFutureProvider<bool> {
  /// See also [canSubscribeToGroup].
  CanSubscribeToGroupProvider(
    MessagingGroup group,
  ) : this._internal(
          (ref) => canSubscribeToGroup(
            ref as CanSubscribeToGroupRef,
            group,
          ),
          from: canSubscribeToGroupProvider,
          name: r'canSubscribeToGroupProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$canSubscribeToGroupHash,
          dependencies: CanSubscribeToGroupFamily._dependencies,
          allTransitiveDependencies:
              CanSubscribeToGroupFamily._allTransitiveDependencies,
          group: group,
        );

  CanSubscribeToGroupProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.group,
  }) : super.internal();

  final MessagingGroup group;

  @override
  Override overrideWith(
    FutureOr<bool> Function(CanSubscribeToGroupRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: CanSubscribeToGroupProvider._internal(
        (ref) => create(ref as CanSubscribeToGroupRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        group: group,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<bool> createElement() {
    return _CanSubscribeToGroupProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is CanSubscribeToGroupProvider && other.group == group;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, group.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin CanSubscribeToGroupRef on AutoDisposeFutureProviderRef<bool> {
  /// The parameter `group` of this provider.
  MessagingGroup get group;
}

class _CanSubscribeToGroupProviderElement
    extends AutoDisposeFutureProviderElement<bool> with CanSubscribeToGroupRef {
  _CanSubscribeToGroupProviderElement(super.provider);

  @override
  MessagingGroup get group => (origin as CanSubscribeToGroupProvider).group;
}

String _$messagingGroupsNotifierHash() =>
    r'c3744e2ea44608ceb922148f28ecae41a34d0dc2';

/// See also [MessagingGroupsNotifier].
@ProviderFor(MessagingGroupsNotifier)
final messagingGroupsNotifierProvider = AutoDisposeAsyncNotifierProvider<
    MessagingGroupsNotifier, List<GroupWithStatus>>.internal(
  MessagingGroupsNotifier.new,
  name: r'messagingGroupsNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$messagingGroupsNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$MessagingGroupsNotifier
    = AutoDisposeAsyncNotifier<List<GroupWithStatus>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
