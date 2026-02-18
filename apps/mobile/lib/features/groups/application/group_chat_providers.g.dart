// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_chat_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$groupMessagesDataSourceHash() =>
    r'015008fc295e220fa73cf278790b1967041b66fd';

/// See also [groupMessagesDataSource].
@ProviderFor(groupMessagesDataSource)
final groupMessagesDataSourceProvider =
    AutoDisposeProvider<GroupMessagesDataSource>.internal(
  groupMessagesDataSource,
  name: r'groupMessagesDataSourceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$groupMessagesDataSourceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef GroupMessagesDataSourceRef
    = AutoDisposeProviderRef<GroupMessagesDataSource>;
String _$groupChatRepositoryHash() =>
    r'c14de72e795c889df40593770616394c3e1d0353';

/// See also [groupChatRepository].
@ProviderFor(groupChatRepository)
final groupChatRepositoryProvider =
    AutoDisposeProvider<GroupChatRepository>.internal(
  groupChatRepository,
  name: r'groupChatRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$groupChatRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef GroupChatRepositoryRef = AutoDisposeProviderRef<GroupChatRepository>;
String _$groupChatMessagesHash() => r'9c999a45e37d7c34dffffc54a834383bb6522270';

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

/// Provider for watching messages in a specific group with caching and lazy loading
///
/// Copied from [groupChatMessages].
@ProviderFor(groupChatMessages)
const groupChatMessagesProvider = GroupChatMessagesFamily();

/// Provider for watching messages in a specific group with caching and lazy loading
///
/// Copied from [groupChatMessages].
class GroupChatMessagesFamily
    extends Family<AsyncValue<List<GroupMessageEntity>>> {
  /// Provider for watching messages in a specific group with caching and lazy loading
  ///
  /// Copied from [groupChatMessages].
  const GroupChatMessagesFamily();

  /// Provider for watching messages in a specific group with caching and lazy loading
  ///
  /// Copied from [groupChatMessages].
  GroupChatMessagesProvider call(
    String groupId,
  ) {
    return GroupChatMessagesProvider(
      groupId,
    );
  }

  @override
  GroupChatMessagesProvider getProviderOverride(
    covariant GroupChatMessagesProvider provider,
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
  String? get name => r'groupChatMessagesProvider';
}

/// Provider for watching messages in a specific group with caching and lazy loading
///
/// Copied from [groupChatMessages].
class GroupChatMessagesProvider
    extends AutoDisposeStreamProvider<List<GroupMessageEntity>> {
  /// Provider for watching messages in a specific group with caching and lazy loading
  ///
  /// Copied from [groupChatMessages].
  GroupChatMessagesProvider(
    String groupId,
  ) : this._internal(
          (ref) => groupChatMessages(
            ref as GroupChatMessagesRef,
            groupId,
          ),
          from: groupChatMessagesProvider,
          name: r'groupChatMessagesProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$groupChatMessagesHash,
          dependencies: GroupChatMessagesFamily._dependencies,
          allTransitiveDependencies:
              GroupChatMessagesFamily._allTransitiveDependencies,
          groupId: groupId,
        );

  GroupChatMessagesProvider._internal(
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
    Stream<List<GroupMessageEntity>> Function(GroupChatMessagesRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: GroupChatMessagesProvider._internal(
        (ref) => create(ref as GroupChatMessagesRef),
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
  AutoDisposeStreamProviderElement<List<GroupMessageEntity>> createElement() {
    return _GroupChatMessagesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is GroupChatMessagesProvider && other.groupId == groupId;
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
mixin GroupChatMessagesRef
    on AutoDisposeStreamProviderRef<List<GroupMessageEntity>> {
  /// The parameter `groupId` of this provider.
  String get groupId;
}

class _GroupChatMessagesProviderElement
    extends AutoDisposeStreamProviderElement<List<GroupMessageEntity>>
    with GroupChatMessagesRef {
  _GroupChatMessagesProviderElement(super.provider);

  @override
  String get groupId => (origin as GroupChatMessagesProvider).groupId;
}

String _$canAccessGroupChatHash() =>
    r'cbcb8af554809c92be16383677a1d14ee7cb7b18';

/// Provider to check if user can access chat for a group
///
/// Copied from [canAccessGroupChat].
@ProviderFor(canAccessGroupChat)
const canAccessGroupChatProvider = CanAccessGroupChatFamily();

/// Provider to check if user can access chat for a group
///
/// Copied from [canAccessGroupChat].
class CanAccessGroupChatFamily extends Family<AsyncValue<bool>> {
  /// Provider to check if user can access chat for a group
  ///
  /// Copied from [canAccessGroupChat].
  const CanAccessGroupChatFamily();

  /// Provider to check if user can access chat for a group
  ///
  /// Copied from [canAccessGroupChat].
  CanAccessGroupChatProvider call(
    String groupId,
  ) {
    return CanAccessGroupChatProvider(
      groupId,
    );
  }

  @override
  CanAccessGroupChatProvider getProviderOverride(
    covariant CanAccessGroupChatProvider provider,
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
  String? get name => r'canAccessGroupChatProvider';
}

/// Provider to check if user can access chat for a group
///
/// Copied from [canAccessGroupChat].
class CanAccessGroupChatProvider extends AutoDisposeFutureProvider<bool> {
  /// Provider to check if user can access chat for a group
  ///
  /// Copied from [canAccessGroupChat].
  CanAccessGroupChatProvider(
    String groupId,
  ) : this._internal(
          (ref) => canAccessGroupChat(
            ref as CanAccessGroupChatRef,
            groupId,
          ),
          from: canAccessGroupChatProvider,
          name: r'canAccessGroupChatProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$canAccessGroupChatHash,
          dependencies: CanAccessGroupChatFamily._dependencies,
          allTransitiveDependencies:
              CanAccessGroupChatFamily._allTransitiveDependencies,
          groupId: groupId,
        );

  CanAccessGroupChatProvider._internal(
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
    FutureOr<bool> Function(CanAccessGroupChatRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: CanAccessGroupChatProvider._internal(
        (ref) => create(ref as CanAccessGroupChatRef),
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
  AutoDisposeFutureProviderElement<bool> createElement() {
    return _CanAccessGroupChatProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is CanAccessGroupChatProvider && other.groupId == groupId;
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
mixin CanAccessGroupChatRef on AutoDisposeFutureProviderRef<bool> {
  /// The parameter `groupId` of this provider.
  String get groupId;
}

class _CanAccessGroupChatProviderElement
    extends AutoDisposeFutureProviderElement<bool> with CanAccessGroupChatRef {
  _CanAccessGroupChatProviderElement(super.provider);

  @override
  String get groupId => (origin as CanAccessGroupChatProvider).groupId;
}

String _$isCurrentUserGroupAdminHash() =>
    r'690b4cac53c703fe018553cce7fff591df73dec3';

/// Provider to check if current user is admin of a specific group
///
/// Copied from [isCurrentUserGroupAdmin].
@ProviderFor(isCurrentUserGroupAdmin)
const isCurrentUserGroupAdminProvider = IsCurrentUserGroupAdminFamily();

/// Provider to check if current user is admin of a specific group
///
/// Copied from [isCurrentUserGroupAdmin].
class IsCurrentUserGroupAdminFamily extends Family<AsyncValue<bool>> {
  /// Provider to check if current user is admin of a specific group
  ///
  /// Copied from [isCurrentUserGroupAdmin].
  const IsCurrentUserGroupAdminFamily();

  /// Provider to check if current user is admin of a specific group
  ///
  /// Copied from [isCurrentUserGroupAdmin].
  IsCurrentUserGroupAdminProvider call(
    String groupId,
  ) {
    return IsCurrentUserGroupAdminProvider(
      groupId,
    );
  }

  @override
  IsCurrentUserGroupAdminProvider getProviderOverride(
    covariant IsCurrentUserGroupAdminProvider provider,
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
  String? get name => r'isCurrentUserGroupAdminProvider';
}

/// Provider to check if current user is admin of a specific group
///
/// Copied from [isCurrentUserGroupAdmin].
class IsCurrentUserGroupAdminProvider extends AutoDisposeFutureProvider<bool> {
  /// Provider to check if current user is admin of a specific group
  ///
  /// Copied from [isCurrentUserGroupAdmin].
  IsCurrentUserGroupAdminProvider(
    String groupId,
  ) : this._internal(
          (ref) => isCurrentUserGroupAdmin(
            ref as IsCurrentUserGroupAdminRef,
            groupId,
          ),
          from: isCurrentUserGroupAdminProvider,
          name: r'isCurrentUserGroupAdminProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$isCurrentUserGroupAdminHash,
          dependencies: IsCurrentUserGroupAdminFamily._dependencies,
          allTransitiveDependencies:
              IsCurrentUserGroupAdminFamily._allTransitiveDependencies,
          groupId: groupId,
        );

  IsCurrentUserGroupAdminProvider._internal(
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
    FutureOr<bool> Function(IsCurrentUserGroupAdminRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: IsCurrentUserGroupAdminProvider._internal(
        (ref) => create(ref as IsCurrentUserGroupAdminRef),
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
  AutoDisposeFutureProviderElement<bool> createElement() {
    return _IsCurrentUserGroupAdminProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is IsCurrentUserGroupAdminProvider && other.groupId == groupId;
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
mixin IsCurrentUserGroupAdminRef on AutoDisposeFutureProviderRef<bool> {
  /// The parameter `groupId` of this provider.
  String get groupId;
}

class _IsCurrentUserGroupAdminProviderElement
    extends AutoDisposeFutureProviderElement<bool>
    with IsCurrentUserGroupAdminRef {
  _IsCurrentUserGroupAdminProviderElement(super.provider);

  @override
  String get groupId => (origin as IsCurrentUserGroupAdminProvider).groupId;
}

String _$generateQuotedPreviewHash() =>
    r'd0154fc853aba5b2d253406bc0370d0d13006272';

/// Provider for generating quoted preview from reply target
///
/// Copied from [generateQuotedPreview].
@ProviderFor(generateQuotedPreview)
const generateQuotedPreviewProvider = GenerateQuotedPreviewFamily();

/// Provider for generating quoted preview from reply target
///
/// Copied from [generateQuotedPreview].
class GenerateQuotedPreviewFamily extends Family<String> {
  /// Provider for generating quoted preview from reply target
  ///
  /// Copied from [generateQuotedPreview].
  const GenerateQuotedPreviewFamily();

  /// Provider for generating quoted preview from reply target
  ///
  /// Copied from [generateQuotedPreview].
  GenerateQuotedPreviewProvider call(
    String messageBody,
  ) {
    return GenerateQuotedPreviewProvider(
      messageBody,
    );
  }

  @override
  GenerateQuotedPreviewProvider getProviderOverride(
    covariant GenerateQuotedPreviewProvider provider,
  ) {
    return call(
      provider.messageBody,
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
  String? get name => r'generateQuotedPreviewProvider';
}

/// Provider for generating quoted preview from reply target
///
/// Copied from [generateQuotedPreview].
class GenerateQuotedPreviewProvider extends AutoDisposeProvider<String> {
  /// Provider for generating quoted preview from reply target
  ///
  /// Copied from [generateQuotedPreview].
  GenerateQuotedPreviewProvider(
    String messageBody,
  ) : this._internal(
          (ref) => generateQuotedPreview(
            ref as GenerateQuotedPreviewRef,
            messageBody,
          ),
          from: generateQuotedPreviewProvider,
          name: r'generateQuotedPreviewProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$generateQuotedPreviewHash,
          dependencies: GenerateQuotedPreviewFamily._dependencies,
          allTransitiveDependencies:
              GenerateQuotedPreviewFamily._allTransitiveDependencies,
          messageBody: messageBody,
        );

  GenerateQuotedPreviewProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.messageBody,
  }) : super.internal();

  final String messageBody;

  @override
  Override overrideWith(
    String Function(GenerateQuotedPreviewRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: GenerateQuotedPreviewProvider._internal(
        (ref) => create(ref as GenerateQuotedPreviewRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        messageBody: messageBody,
      ),
    );
  }

  @override
  AutoDisposeProviderElement<String> createElement() {
    return _GenerateQuotedPreviewProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is GenerateQuotedPreviewProvider &&
        other.messageBody == messageBody;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, messageBody.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin GenerateQuotedPreviewRef on AutoDisposeProviderRef<String> {
  /// The parameter `messageBody` of this provider.
  String get messageBody;
}

class _GenerateQuotedPreviewProviderElement
    extends AutoDisposeProviderElement<String> with GenerateQuotedPreviewRef {
  _GenerateQuotedPreviewProviderElement(super.provider);

  @override
  String get messageBody =>
      (origin as GenerateQuotedPreviewProvider).messageBody;
}

String _$pinnedMessagesHash() => r'dd3a524311669377aaf644f3c92d9cc15657a885';

/// Provider for watching pinned messages in a specific group
///
/// Copied from [pinnedMessages].
@ProviderFor(pinnedMessages)
const pinnedMessagesProvider = PinnedMessagesFamily();

/// Provider for watching pinned messages in a specific group
///
/// Copied from [pinnedMessages].
class PinnedMessagesFamily
    extends Family<AsyncValue<List<GroupMessageEntity>>> {
  /// Provider for watching pinned messages in a specific group
  ///
  /// Copied from [pinnedMessages].
  const PinnedMessagesFamily();

  /// Provider for watching pinned messages in a specific group
  ///
  /// Copied from [pinnedMessages].
  PinnedMessagesProvider call(
    String groupId,
  ) {
    return PinnedMessagesProvider(
      groupId,
    );
  }

  @override
  PinnedMessagesProvider getProviderOverride(
    covariant PinnedMessagesProvider provider,
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
  String? get name => r'pinnedMessagesProvider';
}

/// Provider for watching pinned messages in a specific group
///
/// Copied from [pinnedMessages].
class PinnedMessagesProvider
    extends AutoDisposeFutureProvider<List<GroupMessageEntity>> {
  /// Provider for watching pinned messages in a specific group
  ///
  /// Copied from [pinnedMessages].
  PinnedMessagesProvider(
    String groupId,
  ) : this._internal(
          (ref) => pinnedMessages(
            ref as PinnedMessagesRef,
            groupId,
          ),
          from: pinnedMessagesProvider,
          name: r'pinnedMessagesProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$pinnedMessagesHash,
          dependencies: PinnedMessagesFamily._dependencies,
          allTransitiveDependencies:
              PinnedMessagesFamily._allTransitiveDependencies,
          groupId: groupId,
        );

  PinnedMessagesProvider._internal(
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
    FutureOr<List<GroupMessageEntity>> Function(PinnedMessagesRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: PinnedMessagesProvider._internal(
        (ref) => create(ref as PinnedMessagesRef),
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
  AutoDisposeFutureProviderElement<List<GroupMessageEntity>> createElement() {
    return _PinnedMessagesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PinnedMessagesProvider && other.groupId == groupId;
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
mixin PinnedMessagesRef
    on AutoDisposeFutureProviderRef<List<GroupMessageEntity>> {
  /// The parameter `groupId` of this provider.
  String get groupId;
}

class _PinnedMessagesProviderElement
    extends AutoDisposeFutureProviderElement<List<GroupMessageEntity>>
    with PinnedMessagesRef {
  _PinnedMessagesProviderElement(super.provider);

  @override
  String get groupId => (origin as PinnedMessagesProvider).groupId;
}

String _$searchGroupMessagesHash() =>
    r'4cc29d1f8f504770cac4da2401aa2fc74f9d2fc1';

/// Provider for searching messages in a group
///
/// Copied from [searchGroupMessages].
@ProviderFor(searchGroupMessages)
const searchGroupMessagesProvider = SearchGroupMessagesFamily();

/// Provider for searching messages in a group
///
/// Copied from [searchGroupMessages].
class SearchGroupMessagesFamily
    extends Family<AsyncValue<List<GroupMessageEntity>>> {
  /// Provider for searching messages in a group
  ///
  /// Copied from [searchGroupMessages].
  const SearchGroupMessagesFamily();

  /// Provider for searching messages in a group
  ///
  /// Copied from [searchGroupMessages].
  SearchGroupMessagesProvider call(
    String groupId,
    String query,
  ) {
    return SearchGroupMessagesProvider(
      groupId,
      query,
    );
  }

  @override
  SearchGroupMessagesProvider getProviderOverride(
    covariant SearchGroupMessagesProvider provider,
  ) {
    return call(
      provider.groupId,
      provider.query,
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
  String? get name => r'searchGroupMessagesProvider';
}

/// Provider for searching messages in a group
///
/// Copied from [searchGroupMessages].
class SearchGroupMessagesProvider
    extends AutoDisposeFutureProvider<List<GroupMessageEntity>> {
  /// Provider for searching messages in a group
  ///
  /// Copied from [searchGroupMessages].
  SearchGroupMessagesProvider(
    String groupId,
    String query,
  ) : this._internal(
          (ref) => searchGroupMessages(
            ref as SearchGroupMessagesRef,
            groupId,
            query,
          ),
          from: searchGroupMessagesProvider,
          name: r'searchGroupMessagesProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$searchGroupMessagesHash,
          dependencies: SearchGroupMessagesFamily._dependencies,
          allTransitiveDependencies:
              SearchGroupMessagesFamily._allTransitiveDependencies,
          groupId: groupId,
          query: query,
        );

  SearchGroupMessagesProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.groupId,
    required this.query,
  }) : super.internal();

  final String groupId;
  final String query;

  @override
  Override overrideWith(
    FutureOr<List<GroupMessageEntity>> Function(SearchGroupMessagesRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: SearchGroupMessagesProvider._internal(
        (ref) => create(ref as SearchGroupMessagesRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        groupId: groupId,
        query: query,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<GroupMessageEntity>> createElement() {
    return _SearchGroupMessagesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is SearchGroupMessagesProvider &&
        other.groupId == groupId &&
        other.query == query;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, groupId.hashCode);
    hash = _SystemHash.combine(hash, query.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin SearchGroupMessagesRef
    on AutoDisposeFutureProviderRef<List<GroupMessageEntity>> {
  /// The parameter `groupId` of this provider.
  String get groupId;

  /// The parameter `query` of this provider.
  String get query;
}

class _SearchGroupMessagesProviderElement
    extends AutoDisposeFutureProviderElement<List<GroupMessageEntity>>
    with SearchGroupMessagesRef {
  _SearchGroupMessagesProviderElement(super.provider);

  @override
  String get groupId => (origin as SearchGroupMessagesProvider).groupId;
  @override
  String get query => (origin as SearchGroupMessagesProvider).query;
}

String _$groupChatMessagesPaginatedHash() =>
    r'9fcdd95dcdebdc1b4da7e4ac9359960b57d3e08a';

abstract class _$GroupChatMessagesPaginated
    extends BuildlessAutoDisposeAsyncNotifier<PaginatedMessagesEntityResult> {
  late final String groupId;

  FutureOr<PaginatedMessagesEntityResult> build(
    String groupId,
  );
}

/// Provider for lazy loading older messages with pagination
///
/// Copied from [GroupChatMessagesPaginated].
@ProviderFor(GroupChatMessagesPaginated)
const groupChatMessagesPaginatedProvider = GroupChatMessagesPaginatedFamily();

/// Provider for lazy loading older messages with pagination
///
/// Copied from [GroupChatMessagesPaginated].
class GroupChatMessagesPaginatedFamily
    extends Family<AsyncValue<PaginatedMessagesEntityResult>> {
  /// Provider for lazy loading older messages with pagination
  ///
  /// Copied from [GroupChatMessagesPaginated].
  const GroupChatMessagesPaginatedFamily();

  /// Provider for lazy loading older messages with pagination
  ///
  /// Copied from [GroupChatMessagesPaginated].
  GroupChatMessagesPaginatedProvider call(
    String groupId,
  ) {
    return GroupChatMessagesPaginatedProvider(
      groupId,
    );
  }

  @override
  GroupChatMessagesPaginatedProvider getProviderOverride(
    covariant GroupChatMessagesPaginatedProvider provider,
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
  String? get name => r'groupChatMessagesPaginatedProvider';
}

/// Provider for lazy loading older messages with pagination
///
/// Copied from [GroupChatMessagesPaginated].
class GroupChatMessagesPaginatedProvider
    extends AutoDisposeAsyncNotifierProviderImpl<GroupChatMessagesPaginated,
        PaginatedMessagesEntityResult> {
  /// Provider for lazy loading older messages with pagination
  ///
  /// Copied from [GroupChatMessagesPaginated].
  GroupChatMessagesPaginatedProvider(
    String groupId,
  ) : this._internal(
          () => GroupChatMessagesPaginated()..groupId = groupId,
          from: groupChatMessagesPaginatedProvider,
          name: r'groupChatMessagesPaginatedProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$groupChatMessagesPaginatedHash,
          dependencies: GroupChatMessagesPaginatedFamily._dependencies,
          allTransitiveDependencies:
              GroupChatMessagesPaginatedFamily._allTransitiveDependencies,
          groupId: groupId,
        );

  GroupChatMessagesPaginatedProvider._internal(
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
  FutureOr<PaginatedMessagesEntityResult> runNotifierBuild(
    covariant GroupChatMessagesPaginated notifier,
  ) {
    return notifier.build(
      groupId,
    );
  }

  @override
  Override overrideWith(GroupChatMessagesPaginated Function() create) {
    return ProviderOverride(
      origin: this,
      override: GroupChatMessagesPaginatedProvider._internal(
        () => create()..groupId = groupId,
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
  AutoDisposeAsyncNotifierProviderElement<GroupChatMessagesPaginated,
      PaginatedMessagesEntityResult> createElement() {
    return _GroupChatMessagesPaginatedProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is GroupChatMessagesPaginatedProvider &&
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
mixin GroupChatMessagesPaginatedRef
    on AutoDisposeAsyncNotifierProviderRef<PaginatedMessagesEntityResult> {
  /// The parameter `groupId` of this provider.
  String get groupId;
}

class _GroupChatMessagesPaginatedProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<GroupChatMessagesPaginated,
        PaginatedMessagesEntityResult> with GroupChatMessagesPaginatedRef {
  _GroupChatMessagesPaginatedProviderElement(super.provider);

  @override
  String get groupId => (origin as GroupChatMessagesPaginatedProvider).groupId;
}

String _$groupChatServiceHash() => r'db50ae1e1534db71457201f75b24d53f35238ce5';

/// Service for sending messages (stateless)
///
/// Copied from [GroupChatService].
@ProviderFor(GroupChatService)
final groupChatServiceProvider =
    AutoDisposeNotifierProvider<GroupChatService, bool>.internal(
  GroupChatService.new,
  name: r'groupChatServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$groupChatServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$GroupChatService = AutoDisposeNotifier<bool>;
String _$pinnedMessagesServiceHash() =>
    r'e278038c69b0d8f2167de8e3b971a4f95bf6c4aa';

/// Service for managing pinned messages
///
/// Copied from [PinnedMessagesService].
@ProviderFor(PinnedMessagesService)
final pinnedMessagesServiceProvider =
    AutoDisposeNotifierProvider<PinnedMessagesService, bool>.internal(
  PinnedMessagesService.new,
  name: r'pinnedMessagesServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$pinnedMessagesServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$PinnedMessagesService = AutoDisposeNotifier<bool>;
String _$messageReactionsServiceHash() =>
    r'83dec155f5604395ae5e2cab10a721bcdd3430f4';

/// Service for managing message reactions
///
/// Copied from [MessageReactionsService].
@ProviderFor(MessageReactionsService)
final messageReactionsServiceProvider =
    AutoDisposeNotifierProvider<MessageReactionsService, bool>.internal(
  MessageReactionsService.new,
  name: r'messageReactionsServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$messageReactionsServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$MessageReactionsService = AutoDisposeNotifier<bool>;
String _$messageCacheManagerHash() =>
    r'7e538d1566805b5f3f34387b2b67c2ebd7e741c3';

/// Provider for managing message cache
///
/// Copied from [MessageCacheManager].
@ProviderFor(MessageCacheManager)
final messageCacheManagerProvider = AutoDisposeNotifierProvider<
    MessageCacheManager, Map<String, DateTime>>.internal(
  MessageCacheManager.new,
  name: r'messageCacheManagerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$messageCacheManagerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$MessageCacheManager = AutoDisposeNotifier<Map<String, DateTime>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
