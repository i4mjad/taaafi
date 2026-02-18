// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ban_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$banNotifierHash() => r'efb4e8d760a3209afe43b5f99a6293e6737e56e8';

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

abstract class _$BanNotifier
    extends BuildlessAutoDisposeAsyncNotifier<List<Ban>> {
  late final String userId;

  FutureOr<List<Ban>> build(
    String userId,
  );
}

/// Notifier for managing ban state with real-time updates
///
/// Copied from [BanNotifier].
@ProviderFor(BanNotifier)
const banNotifierProvider = BanNotifierFamily();

/// Notifier for managing ban state with real-time updates
///
/// Copied from [BanNotifier].
class BanNotifierFamily extends Family<AsyncValue<List<Ban>>> {
  /// Notifier for managing ban state with real-time updates
  ///
  /// Copied from [BanNotifier].
  const BanNotifierFamily();

  /// Notifier for managing ban state with real-time updates
  ///
  /// Copied from [BanNotifier].
  BanNotifierProvider call(
    String userId,
  ) {
    return BanNotifierProvider(
      userId,
    );
  }

  @override
  BanNotifierProvider getProviderOverride(
    covariant BanNotifierProvider provider,
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
  String? get name => r'banNotifierProvider';
}

/// Notifier for managing ban state with real-time updates
///
/// Copied from [BanNotifier].
class BanNotifierProvider
    extends AutoDisposeAsyncNotifierProviderImpl<BanNotifier, List<Ban>> {
  /// Notifier for managing ban state with real-time updates
  ///
  /// Copied from [BanNotifier].
  BanNotifierProvider(
    String userId,
  ) : this._internal(
          () => BanNotifier()..userId = userId,
          from: banNotifierProvider,
          name: r'banNotifierProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$banNotifierHash,
          dependencies: BanNotifierFamily._dependencies,
          allTransitiveDependencies:
              BanNotifierFamily._allTransitiveDependencies,
          userId: userId,
        );

  BanNotifierProvider._internal(
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
  FutureOr<List<Ban>> runNotifierBuild(
    covariant BanNotifier notifier,
  ) {
    return notifier.build(
      userId,
    );
  }

  @override
  Override overrideWith(BanNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: BanNotifierProvider._internal(
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
  AutoDisposeAsyncNotifierProviderElement<BanNotifier, List<Ban>>
      createElement() {
    return _BanNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is BanNotifierProvider && other.userId == userId;
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
mixin BanNotifierRef on AutoDisposeAsyncNotifierProviderRef<List<Ban>> {
  /// The parameter `userId` of this provider.
  String get userId;
}

class _BanNotifierProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<BanNotifier, List<Ban>>
    with BanNotifierRef {
  _BanNotifierProviderElement(super.provider);

  @override
  String get userId => (origin as BanNotifierProvider).userId;
}

String _$currentUserBanNotifierHash() =>
    r'9c6ff51eaf283ba46ccd57179c72aa19ee4ad691';

/// Notifier for current user bans
///
/// Copied from [CurrentUserBanNotifier].
@ProviderFor(CurrentUserBanNotifier)
final currentUserBanNotifierProvider = AutoDisposeAsyncNotifierProvider<
    CurrentUserBanNotifier, List<Ban>>.internal(
  CurrentUserBanNotifier.new,
  name: r'currentUserBanNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$currentUserBanNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$CurrentUserBanNotifier = AutoDisposeAsyncNotifier<List<Ban>>;
String _$banStreamNotifierHash() => r'50f3a0319e300833a75910bd384f78ad930326d5';

abstract class _$BanStreamNotifier
    extends BuildlessAutoDisposeStreamNotifier<List<Ban>> {
  late final String userId;

  Stream<List<Ban>> build(
    String userId,
  );
}

/// Stream notifier for real-time ban updates
///
/// Copied from [BanStreamNotifier].
@ProviderFor(BanStreamNotifier)
const banStreamNotifierProvider = BanStreamNotifierFamily();

/// Stream notifier for real-time ban updates
///
/// Copied from [BanStreamNotifier].
class BanStreamNotifierFamily extends Family<AsyncValue<List<Ban>>> {
  /// Stream notifier for real-time ban updates
  ///
  /// Copied from [BanStreamNotifier].
  const BanStreamNotifierFamily();

  /// Stream notifier for real-time ban updates
  ///
  /// Copied from [BanStreamNotifier].
  BanStreamNotifierProvider call(
    String userId,
  ) {
    return BanStreamNotifierProvider(
      userId,
    );
  }

  @override
  BanStreamNotifierProvider getProviderOverride(
    covariant BanStreamNotifierProvider provider,
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
  String? get name => r'banStreamNotifierProvider';
}

/// Stream notifier for real-time ban updates
///
/// Copied from [BanStreamNotifier].
class BanStreamNotifierProvider extends AutoDisposeStreamNotifierProviderImpl<
    BanStreamNotifier, List<Ban>> {
  /// Stream notifier for real-time ban updates
  ///
  /// Copied from [BanStreamNotifier].
  BanStreamNotifierProvider(
    String userId,
  ) : this._internal(
          () => BanStreamNotifier()..userId = userId,
          from: banStreamNotifierProvider,
          name: r'banStreamNotifierProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$banStreamNotifierHash,
          dependencies: BanStreamNotifierFamily._dependencies,
          allTransitiveDependencies:
              BanStreamNotifierFamily._allTransitiveDependencies,
          userId: userId,
        );

  BanStreamNotifierProvider._internal(
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
  Stream<List<Ban>> runNotifierBuild(
    covariant BanStreamNotifier notifier,
  ) {
    return notifier.build(
      userId,
    );
  }

  @override
  Override overrideWith(BanStreamNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: BanStreamNotifierProvider._internal(
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
  AutoDisposeStreamNotifierProviderElement<BanStreamNotifier, List<Ban>>
      createElement() {
    return _BanStreamNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is BanStreamNotifierProvider && other.userId == userId;
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
mixin BanStreamNotifierRef on AutoDisposeStreamNotifierProviderRef<List<Ban>> {
  /// The parameter `userId` of this provider.
  String get userId;
}

class _BanStreamNotifierProviderElement
    extends AutoDisposeStreamNotifierProviderElement<BanStreamNotifier,
        List<Ban>> with BanStreamNotifierRef {
  _BanStreamNotifierProviderElement(super.provider);

  @override
  String get userId => (origin as BanStreamNotifierProvider).userId;
}

String _$currentUserBanStreamNotifierHash() =>
    r'8aa9edda10b28c11383886241311413d84c72c5e';

/// Stream notifier for current user ban updates
///
/// Copied from [CurrentUserBanStreamNotifier].
@ProviderFor(CurrentUserBanStreamNotifier)
final currentUserBanStreamNotifierProvider = AutoDisposeStreamNotifierProvider<
    CurrentUserBanStreamNotifier, List<Ban>>.internal(
  CurrentUserBanStreamNotifier.new,
  name: r'currentUserBanStreamNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$currentUserBanStreamNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$CurrentUserBanStreamNotifier = AutoDisposeStreamNotifier<List<Ban>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
