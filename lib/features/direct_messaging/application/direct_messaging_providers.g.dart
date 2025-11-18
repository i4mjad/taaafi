// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'direct_messaging_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$directMessagesDataSourceHash() =>
    r'5722db8e78b83e34be66c0e746e66c621b20b5b9';

/// See also [directMessagesDataSource].
@ProviderFor(directMessagesDataSource)
final directMessagesDataSourceProvider =
    AutoDisposeProvider<DirectMessagesDataSource>.internal(
  directMessagesDataSource,
  name: r'directMessagesDataSourceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$directMessagesDataSourceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef DirectMessagesDataSourceRef
    = AutoDisposeProviderRef<DirectMessagesDataSource>;
String _$conversationsDataSourceHash() =>
    r'12f1bb97fa098d3ca1030374c3531ad8c7549b2c';

/// See also [conversationsDataSource].
@ProviderFor(conversationsDataSource)
final conversationsDataSourceProvider =
    AutoDisposeProvider<ConversationsDataSource>.internal(
  conversationsDataSource,
  name: r'conversationsDataSourceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$conversationsDataSourceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ConversationsDataSourceRef
    = AutoDisposeProviderRef<ConversationsDataSource>;
String _$userBlocksDataSourceHash() =>
    r'5b155bf8d7f057b2e0e4b5b200fb01d58fe2e422';

/// See also [userBlocksDataSource].
@ProviderFor(userBlocksDataSource)
final userBlocksDataSourceProvider =
    AutoDisposeProvider<UserBlocksDataSource>.internal(
  userBlocksDataSource,
  name: r'userBlocksDataSourceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$userBlocksDataSourceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef UserBlocksDataSourceRef = AutoDisposeProviderRef<UserBlocksDataSource>;
String _$directChatRepositoryHash() =>
    r'a3f7457d445160e080ac83b2fe591320b5b49f88';

/// See also [directChatRepository].
@ProviderFor(directChatRepository)
final directChatRepositoryProvider =
    AutoDisposeProvider<DirectChatRepository>.internal(
  directChatRepository,
  name: r'directChatRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$directChatRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef DirectChatRepositoryRef = AutoDisposeProviderRef<DirectChatRepository>;
String _$conversationsRepositoryHash() =>
    r'e9e116203211db76befc0e6ecea92d0977ee81f6';

/// See also [conversationsRepository].
@ProviderFor(conversationsRepository)
final conversationsRepositoryProvider =
    AutoDisposeProvider<ConversationsRepository>.internal(
  conversationsRepository,
  name: r'conversationsRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$conversationsRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ConversationsRepositoryRef
    = AutoDisposeProviderRef<ConversationsRepository>;
String _$userBlocksRepositoryHash() =>
    r'f0e75d5653aaeb9f79a4cf59853d5ec19ee33df1';

/// See also [userBlocksRepository].
@ProviderFor(userBlocksRepository)
final userBlocksRepositoryProvider =
    AutoDisposeProvider<UserBlocksRepository>.internal(
  userBlocksRepository,
  name: r'userBlocksRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$userBlocksRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef UserBlocksRepositoryRef = AutoDisposeProviderRef<UserBlocksRepository>;
String _$directChatMessagesHash() =>
    r'0af486d4b8594e08da8a33d7436ef99c7bd1b814';

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

/// Provider for watching messages in a specific conversation
///
/// Copied from [directChatMessages].
@ProviderFor(directChatMessages)
const directChatMessagesProvider = DirectChatMessagesFamily();

/// Provider for watching messages in a specific conversation
///
/// Copied from [directChatMessages].
class DirectChatMessagesFamily
    extends Family<AsyncValue<List<DirectMessageEntity>>> {
  /// Provider for watching messages in a specific conversation
  ///
  /// Copied from [directChatMessages].
  const DirectChatMessagesFamily();

  /// Provider for watching messages in a specific conversation
  ///
  /// Copied from [directChatMessages].
  DirectChatMessagesProvider call(
    String conversationId,
  ) {
    return DirectChatMessagesProvider(
      conversationId,
    );
  }

  @override
  DirectChatMessagesProvider getProviderOverride(
    covariant DirectChatMessagesProvider provider,
  ) {
    return call(
      provider.conversationId,
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
  String? get name => r'directChatMessagesProvider';
}

/// Provider for watching messages in a specific conversation
///
/// Copied from [directChatMessages].
class DirectChatMessagesProvider
    extends AutoDisposeStreamProvider<List<DirectMessageEntity>> {
  /// Provider for watching messages in a specific conversation
  ///
  /// Copied from [directChatMessages].
  DirectChatMessagesProvider(
    String conversationId,
  ) : this._internal(
          (ref) => directChatMessages(
            ref as DirectChatMessagesRef,
            conversationId,
          ),
          from: directChatMessagesProvider,
          name: r'directChatMessagesProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$directChatMessagesHash,
          dependencies: DirectChatMessagesFamily._dependencies,
          allTransitiveDependencies:
              DirectChatMessagesFamily._allTransitiveDependencies,
          conversationId: conversationId,
        );

  DirectChatMessagesProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.conversationId,
  }) : super.internal();

  final String conversationId;

  @override
  Override overrideWith(
    Stream<List<DirectMessageEntity>> Function(DirectChatMessagesRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: DirectChatMessagesProvider._internal(
        (ref) => create(ref as DirectChatMessagesRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        conversationId: conversationId,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<List<DirectMessageEntity>> createElement() {
    return _DirectChatMessagesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is DirectChatMessagesProvider &&
        other.conversationId == conversationId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, conversationId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin DirectChatMessagesRef
    on AutoDisposeStreamProviderRef<List<DirectMessageEntity>> {
  /// The parameter `conversationId` of this provider.
  String get conversationId;
}

class _DirectChatMessagesProviderElement
    extends AutoDisposeStreamProviderElement<List<DirectMessageEntity>>
    with DirectChatMessagesRef {
  _DirectChatMessagesProviderElement(super.provider);

  @override
  String get conversationId =>
      (origin as DirectChatMessagesProvider).conversationId;
}

String _$userConversationsHash() => r'683b66f8eca85565c3828f72cf67e4e3eacd7c48';

/// Provider for watching user's conversations
///
/// Copied from [userConversations].
@ProviderFor(userConversations)
final userConversationsProvider =
    AutoDisposeStreamProvider<List<DirectConversationEntity>>.internal(
  userConversations,
  name: r'userConversationsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$userConversationsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef UserConversationsRef
    = AutoDisposeStreamProviderRef<List<DirectConversationEntity>>;
String _$findOrCreateConversationHash() =>
    r'55ea8bdcf4cdd934cb5047efe8f65f17c0b2ebee';

/// Provider to find or create a conversation
///
/// Copied from [findOrCreateConversation].
@ProviderFor(findOrCreateConversation)
const findOrCreateConversationProvider = FindOrCreateConversationFamily();

/// Provider to find or create a conversation
///
/// Copied from [findOrCreateConversation].
class FindOrCreateConversationFamily
    extends Family<AsyncValue<DirectConversationEntity?>> {
  /// Provider to find or create a conversation
  ///
  /// Copied from [findOrCreateConversation].
  const FindOrCreateConversationFamily();

  /// Provider to find or create a conversation
  ///
  /// Copied from [findOrCreateConversation].
  FindOrCreateConversationProvider call(
    String otherCpId,
  ) {
    return FindOrCreateConversationProvider(
      otherCpId,
    );
  }

  @override
  FindOrCreateConversationProvider getProviderOverride(
    covariant FindOrCreateConversationProvider provider,
  ) {
    return call(
      provider.otherCpId,
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
  String? get name => r'findOrCreateConversationProvider';
}

/// Provider to find or create a conversation
///
/// Copied from [findOrCreateConversation].
class FindOrCreateConversationProvider
    extends AutoDisposeFutureProvider<DirectConversationEntity?> {
  /// Provider to find or create a conversation
  ///
  /// Copied from [findOrCreateConversation].
  FindOrCreateConversationProvider(
    String otherCpId,
  ) : this._internal(
          (ref) => findOrCreateConversation(
            ref as FindOrCreateConversationRef,
            otherCpId,
          ),
          from: findOrCreateConversationProvider,
          name: r'findOrCreateConversationProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$findOrCreateConversationHash,
          dependencies: FindOrCreateConversationFamily._dependencies,
          allTransitiveDependencies:
              FindOrCreateConversationFamily._allTransitiveDependencies,
          otherCpId: otherCpId,
        );

  FindOrCreateConversationProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.otherCpId,
  }) : super.internal();

  final String otherCpId;

  @override
  Override overrideWith(
    FutureOr<DirectConversationEntity?> Function(
            FindOrCreateConversationRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: FindOrCreateConversationProvider._internal(
        (ref) => create(ref as FindOrCreateConversationRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        otherCpId: otherCpId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<DirectConversationEntity?> createElement() {
    return _FindOrCreateConversationProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is FindOrCreateConversationProvider &&
        other.otherCpId == otherCpId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, otherCpId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin FindOrCreateConversationRef
    on AutoDisposeFutureProviderRef<DirectConversationEntity?> {
  /// The parameter `otherCpId` of this provider.
  String get otherCpId;
}

class _FindOrCreateConversationProviderElement
    extends AutoDisposeFutureProviderElement<DirectConversationEntity?>
    with FindOrCreateConversationRef {
  _FindOrCreateConversationProviderElement(super.provider);

  @override
  String get otherCpId =>
      (origin as FindOrCreateConversationProvider).otherCpId;
}

String _$didIBlockUserHash() => r'05855b397b69384d57f6a60d64fbb15d6871d83f';

/// Check if I have blocked a user
///
/// Copied from [didIBlockUser].
@ProviderFor(didIBlockUser)
const didIBlockUserProvider = DidIBlockUserFamily();

/// Check if I have blocked a user
///
/// Copied from [didIBlockUser].
class DidIBlockUserFamily extends Family<AsyncValue<bool>> {
  /// Check if I have blocked a user
  ///
  /// Copied from [didIBlockUser].
  const DidIBlockUserFamily();

  /// Check if I have blocked a user
  ///
  /// Copied from [didIBlockUser].
  DidIBlockUserProvider call(
    String otherCpId,
  ) {
    return DidIBlockUserProvider(
      otherCpId,
    );
  }

  @override
  DidIBlockUserProvider getProviderOverride(
    covariant DidIBlockUserProvider provider,
  ) {
    return call(
      provider.otherCpId,
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
  String? get name => r'didIBlockUserProvider';
}

/// Check if I have blocked a user
///
/// Copied from [didIBlockUser].
class DidIBlockUserProvider extends AutoDisposeFutureProvider<bool> {
  /// Check if I have blocked a user
  ///
  /// Copied from [didIBlockUser].
  DidIBlockUserProvider(
    String otherCpId,
  ) : this._internal(
          (ref) => didIBlockUser(
            ref as DidIBlockUserRef,
            otherCpId,
          ),
          from: didIBlockUserProvider,
          name: r'didIBlockUserProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$didIBlockUserHash,
          dependencies: DidIBlockUserFamily._dependencies,
          allTransitiveDependencies:
              DidIBlockUserFamily._allTransitiveDependencies,
          otherCpId: otherCpId,
        );

  DidIBlockUserProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.otherCpId,
  }) : super.internal();

  final String otherCpId;

  @override
  Override overrideWith(
    FutureOr<bool> Function(DidIBlockUserRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: DidIBlockUserProvider._internal(
        (ref) => create(ref as DidIBlockUserRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        otherCpId: otherCpId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<bool> createElement() {
    return _DidIBlockUserProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is DidIBlockUserProvider && other.otherCpId == otherCpId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, otherCpId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin DidIBlockUserRef on AutoDisposeFutureProviderRef<bool> {
  /// The parameter `otherCpId` of this provider.
  String get otherCpId;
}

class _DidIBlockUserProviderElement
    extends AutoDisposeFutureProviderElement<bool> with DidIBlockUserRef {
  _DidIBlockUserProviderElement(super.provider);

  @override
  String get otherCpId => (origin as DidIBlockUserProvider).otherCpId;
}

String _$hasUserBlockedMeHash() => r'ccf2af20cc5bc0510c4c36108853a197459b6991';

/// Check if another user has blocked me
///
/// Copied from [hasUserBlockedMe].
@ProviderFor(hasUserBlockedMe)
const hasUserBlockedMeProvider = HasUserBlockedMeFamily();

/// Check if another user has blocked me
///
/// Copied from [hasUserBlockedMe].
class HasUserBlockedMeFamily extends Family<AsyncValue<bool>> {
  /// Check if another user has blocked me
  ///
  /// Copied from [hasUserBlockedMe].
  const HasUserBlockedMeFamily();

  /// Check if another user has blocked me
  ///
  /// Copied from [hasUserBlockedMe].
  HasUserBlockedMeProvider call(
    String otherCpId,
  ) {
    return HasUserBlockedMeProvider(
      otherCpId,
    );
  }

  @override
  HasUserBlockedMeProvider getProviderOverride(
    covariant HasUserBlockedMeProvider provider,
  ) {
    return call(
      provider.otherCpId,
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
  String? get name => r'hasUserBlockedMeProvider';
}

/// Check if another user has blocked me
///
/// Copied from [hasUserBlockedMe].
class HasUserBlockedMeProvider extends AutoDisposeFutureProvider<bool> {
  /// Check if another user has blocked me
  ///
  /// Copied from [hasUserBlockedMe].
  HasUserBlockedMeProvider(
    String otherCpId,
  ) : this._internal(
          (ref) => hasUserBlockedMe(
            ref as HasUserBlockedMeRef,
            otherCpId,
          ),
          from: hasUserBlockedMeProvider,
          name: r'hasUserBlockedMeProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$hasUserBlockedMeHash,
          dependencies: HasUserBlockedMeFamily._dependencies,
          allTransitiveDependencies:
              HasUserBlockedMeFamily._allTransitiveDependencies,
          otherCpId: otherCpId,
        );

  HasUserBlockedMeProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.otherCpId,
  }) : super.internal();

  final String otherCpId;

  @override
  Override overrideWith(
    FutureOr<bool> Function(HasUserBlockedMeRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: HasUserBlockedMeProvider._internal(
        (ref) => create(ref as HasUserBlockedMeRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        otherCpId: otherCpId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<bool> createElement() {
    return _HasUserBlockedMeProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is HasUserBlockedMeProvider && other.otherCpId == otherCpId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, otherCpId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin HasUserBlockedMeRef on AutoDisposeFutureProviderRef<bool> {
  /// The parameter `otherCpId` of this provider.
  String get otherCpId;
}

class _HasUserBlockedMeProviderElement
    extends AutoDisposeFutureProviderElement<bool> with HasUserBlockedMeRef {
  _HasUserBlockedMeProviderElement(super.provider);

  @override
  String get otherCpId => (origin as HasUserBlockedMeProvider).otherCpId;
}

String _$isAnyBlockBetweenHash() => r'3475dee0f7d91034ba5d233e512368844c3dabf3';

/// Check if there's any block between me and another user (either direction)
///
/// Copied from [isAnyBlockBetween].
@ProviderFor(isAnyBlockBetween)
const isAnyBlockBetweenProvider = IsAnyBlockBetweenFamily();

/// Check if there's any block between me and another user (either direction)
///
/// Copied from [isAnyBlockBetween].
class IsAnyBlockBetweenFamily extends Family<AsyncValue<bool>> {
  /// Check if there's any block between me and another user (either direction)
  ///
  /// Copied from [isAnyBlockBetween].
  const IsAnyBlockBetweenFamily();

  /// Check if there's any block between me and another user (either direction)
  ///
  /// Copied from [isAnyBlockBetween].
  IsAnyBlockBetweenProvider call(
    String otherCpId,
  ) {
    return IsAnyBlockBetweenProvider(
      otherCpId,
    );
  }

  @override
  IsAnyBlockBetweenProvider getProviderOverride(
    covariant IsAnyBlockBetweenProvider provider,
  ) {
    return call(
      provider.otherCpId,
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
  String? get name => r'isAnyBlockBetweenProvider';
}

/// Check if there's any block between me and another user (either direction)
///
/// Copied from [isAnyBlockBetween].
class IsAnyBlockBetweenProvider extends AutoDisposeFutureProvider<bool> {
  /// Check if there's any block between me and another user (either direction)
  ///
  /// Copied from [isAnyBlockBetween].
  IsAnyBlockBetweenProvider(
    String otherCpId,
  ) : this._internal(
          (ref) => isAnyBlockBetween(
            ref as IsAnyBlockBetweenRef,
            otherCpId,
          ),
          from: isAnyBlockBetweenProvider,
          name: r'isAnyBlockBetweenProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$isAnyBlockBetweenHash,
          dependencies: IsAnyBlockBetweenFamily._dependencies,
          allTransitiveDependencies:
              IsAnyBlockBetweenFamily._allTransitiveDependencies,
          otherCpId: otherCpId,
        );

  IsAnyBlockBetweenProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.otherCpId,
  }) : super.internal();

  final String otherCpId;

  @override
  Override overrideWith(
    FutureOr<bool> Function(IsAnyBlockBetweenRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: IsAnyBlockBetweenProvider._internal(
        (ref) => create(ref as IsAnyBlockBetweenRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        otherCpId: otherCpId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<bool> createElement() {
    return _IsAnyBlockBetweenProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is IsAnyBlockBetweenProvider && other.otherCpId == otherCpId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, otherCpId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin IsAnyBlockBetweenRef on AutoDisposeFutureProviderRef<bool> {
  /// The parameter `otherCpId` of this provider.
  String get otherCpId;
}

class _IsAnyBlockBetweenProviderElement
    extends AutoDisposeFutureProviderElement<bool> with IsAnyBlockBetweenRef {
  _IsAnyBlockBetweenProviderElement(super.provider);

  @override
  String get otherCpId => (origin as IsAnyBlockBetweenProvider).otherCpId;
}

String _$conversationLastVisibleMessageHash() =>
    r'885036bbb18e663d020e228c9b463c7e6621ea16';

/// Get the actual last visible message for a conversation
/// This fetches the most recent message that should be visible to the current user
///
/// Copied from [conversationLastVisibleMessage].
@ProviderFor(conversationLastVisibleMessage)
const conversationLastVisibleMessageProvider =
    ConversationLastVisibleMessageFamily();

/// Get the actual last visible message for a conversation
/// This fetches the most recent message that should be visible to the current user
///
/// Copied from [conversationLastVisibleMessage].
class ConversationLastVisibleMessageFamily extends Family<AsyncValue<String?>> {
  /// Get the actual last visible message for a conversation
  /// This fetches the most recent message that should be visible to the current user
  ///
  /// Copied from [conversationLastVisibleMessage].
  const ConversationLastVisibleMessageFamily();

  /// Get the actual last visible message for a conversation
  /// This fetches the most recent message that should be visible to the current user
  ///
  /// Copied from [conversationLastVisibleMessage].
  ConversationLastVisibleMessageProvider call(
    String conversationId,
  ) {
    return ConversationLastVisibleMessageProvider(
      conversationId,
    );
  }

  @override
  ConversationLastVisibleMessageProvider getProviderOverride(
    covariant ConversationLastVisibleMessageProvider provider,
  ) {
    return call(
      provider.conversationId,
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
  String? get name => r'conversationLastVisibleMessageProvider';
}

/// Get the actual last visible message for a conversation
/// This fetches the most recent message that should be visible to the current user
///
/// Copied from [conversationLastVisibleMessage].
class ConversationLastVisibleMessageProvider
    extends AutoDisposeFutureProvider<String?> {
  /// Get the actual last visible message for a conversation
  /// This fetches the most recent message that should be visible to the current user
  ///
  /// Copied from [conversationLastVisibleMessage].
  ConversationLastVisibleMessageProvider(
    String conversationId,
  ) : this._internal(
          (ref) => conversationLastVisibleMessage(
            ref as ConversationLastVisibleMessageRef,
            conversationId,
          ),
          from: conversationLastVisibleMessageProvider,
          name: r'conversationLastVisibleMessageProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$conversationLastVisibleMessageHash,
          dependencies: ConversationLastVisibleMessageFamily._dependencies,
          allTransitiveDependencies:
              ConversationLastVisibleMessageFamily._allTransitiveDependencies,
          conversationId: conversationId,
        );

  ConversationLastVisibleMessageProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.conversationId,
  }) : super.internal();

  final String conversationId;

  @override
  Override overrideWith(
    FutureOr<String?> Function(ConversationLastVisibleMessageRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ConversationLastVisibleMessageProvider._internal(
        (ref) => create(ref as ConversationLastVisibleMessageRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        conversationId: conversationId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<String?> createElement() {
    return _ConversationLastVisibleMessageProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ConversationLastVisibleMessageProvider &&
        other.conversationId == conversationId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, conversationId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ConversationLastVisibleMessageRef
    on AutoDisposeFutureProviderRef<String?> {
  /// The parameter `conversationId` of this provider.
  String get conversationId;
}

class _ConversationLastVisibleMessageProviderElement
    extends AutoDisposeFutureProviderElement<String?>
    with ConversationLastVisibleMessageRef {
  _ConversationLastVisibleMessageProviderElement(super.provider);

  @override
  String get conversationId =>
      (origin as ConversationLastVisibleMessageProvider).conversationId;
}

String _$canAccessDirectChatHash() =>
    r'707820ddd987ba7448597589297df24b0d1db25e';

/// Provider to check if user can access a direct chat conversation
///
/// Copied from [canAccessDirectChat].
@ProviderFor(canAccessDirectChat)
const canAccessDirectChatProvider = CanAccessDirectChatFamily();

/// Provider to check if user can access a direct chat conversation
///
/// Copied from [canAccessDirectChat].
class CanAccessDirectChatFamily extends Family<AsyncValue<bool>> {
  /// Provider to check if user can access a direct chat conversation
  ///
  /// Copied from [canAccessDirectChat].
  const CanAccessDirectChatFamily();

  /// Provider to check if user can access a direct chat conversation
  ///
  /// Copied from [canAccessDirectChat].
  CanAccessDirectChatProvider call(
    String conversationId,
  ) {
    return CanAccessDirectChatProvider(
      conversationId,
    );
  }

  @override
  CanAccessDirectChatProvider getProviderOverride(
    covariant CanAccessDirectChatProvider provider,
  ) {
    return call(
      provider.conversationId,
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
  String? get name => r'canAccessDirectChatProvider';
}

/// Provider to check if user can access a direct chat conversation
///
/// Copied from [canAccessDirectChat].
class CanAccessDirectChatProvider extends AutoDisposeFutureProvider<bool> {
  /// Provider to check if user can access a direct chat conversation
  ///
  /// Copied from [canAccessDirectChat].
  CanAccessDirectChatProvider(
    String conversationId,
  ) : this._internal(
          (ref) => canAccessDirectChat(
            ref as CanAccessDirectChatRef,
            conversationId,
          ),
          from: canAccessDirectChatProvider,
          name: r'canAccessDirectChatProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$canAccessDirectChatHash,
          dependencies: CanAccessDirectChatFamily._dependencies,
          allTransitiveDependencies:
              CanAccessDirectChatFamily._allTransitiveDependencies,
          conversationId: conversationId,
        );

  CanAccessDirectChatProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.conversationId,
  }) : super.internal();

  final String conversationId;

  @override
  Override overrideWith(
    FutureOr<bool> Function(CanAccessDirectChatRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: CanAccessDirectChatProvider._internal(
        (ref) => create(ref as CanAccessDirectChatRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        conversationId: conversationId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<bool> createElement() {
    return _CanAccessDirectChatProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is CanAccessDirectChatProvider &&
        other.conversationId == conversationId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, conversationId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin CanAccessDirectChatRef on AutoDisposeFutureProviderRef<bool> {
  /// The parameter `conversationId` of this provider.
  String get conversationId;
}

class _CanAccessDirectChatProviderElement
    extends AutoDisposeFutureProviderElement<bool> with CanAccessDirectChatRef {
  _CanAccessDirectChatProviderElement(super.provider);

  @override
  String get conversationId =>
      (origin as CanAccessDirectChatProvider).conversationId;
}

String _$generateQuotedPreviewHash() =>
    r'd0154fc853aba5b2d253406bc0370d0d13006272';

/// Generate quoted preview from message body
///
/// Copied from [generateQuotedPreview].
@ProviderFor(generateQuotedPreview)
const generateQuotedPreviewProvider = GenerateQuotedPreviewFamily();

/// Generate quoted preview from message body
///
/// Copied from [generateQuotedPreview].
class GenerateQuotedPreviewFamily extends Family<String> {
  /// Generate quoted preview from message body
  ///
  /// Copied from [generateQuotedPreview].
  const GenerateQuotedPreviewFamily();

  /// Generate quoted preview from message body
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

/// Generate quoted preview from message body
///
/// Copied from [generateQuotedPreview].
class GenerateQuotedPreviewProvider extends AutoDisposeProvider<String> {
  /// Generate quoted preview from message body
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

String _$directChatControllerHash() =>
    r'cc51d77e5975024239bf9b9a747dbe33154274b3';

/// Controller for sending messages in direct chat
///
/// Copied from [DirectChatController].
@ProviderFor(DirectChatController)
final directChatControllerProvider =
    AutoDisposeNotifierProvider<DirectChatController, bool>.internal(
  DirectChatController.new,
  name: r'directChatControllerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$directChatControllerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$DirectChatController = AutoDisposeNotifier<bool>;
String _$conversationActionsControllerHash() =>
    r'82ec10779e0dd68ec5aaf6ce144e445e0424577c';

/// Controller for conversation actions (mute, archive, delete, etc.)
///
/// Copied from [ConversationActionsController].
@ProviderFor(ConversationActionsController)
final conversationActionsControllerProvider =
    AutoDisposeNotifierProvider<ConversationActionsController, bool>.internal(
  ConversationActionsController.new,
  name: r'conversationActionsControllerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$conversationActionsControllerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ConversationActionsController = AutoDisposeNotifier<bool>;
String _$blockControllerHash() => r'799f53b5f035aefff7104599142828a803aebaa4';

/// Controller for blocking/unblocking users
///
/// Copied from [BlockController].
@ProviderFor(BlockController)
final blockControllerProvider =
    AutoDisposeNotifierProvider<BlockController, bool>.internal(
  BlockController.new,
  name: r'blockControllerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$blockControllerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$BlockController = AutoDisposeNotifier<bool>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
