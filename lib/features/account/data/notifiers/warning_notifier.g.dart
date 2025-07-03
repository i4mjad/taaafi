// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'warning_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$warningNotifierHash() => r'0ae8f2de6128de2b278163783c83726527f3b436';

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

abstract class _$WarningNotifier
    extends BuildlessAutoDisposeAsyncNotifier<List<Warning>> {
  late final String userId;

  FutureOr<List<Warning>> build(
    String userId,
  );
}

/// Notifier for managing warning state with real-time updates
///
/// Copied from [WarningNotifier].
@ProviderFor(WarningNotifier)
const warningNotifierProvider = WarningNotifierFamily();

/// Notifier for managing warning state with real-time updates
///
/// Copied from [WarningNotifier].
class WarningNotifierFamily extends Family<AsyncValue<List<Warning>>> {
  /// Notifier for managing warning state with real-time updates
  ///
  /// Copied from [WarningNotifier].
  const WarningNotifierFamily();

  /// Notifier for managing warning state with real-time updates
  ///
  /// Copied from [WarningNotifier].
  WarningNotifierProvider call(
    String userId,
  ) {
    return WarningNotifierProvider(
      userId,
    );
  }

  @override
  WarningNotifierProvider getProviderOverride(
    covariant WarningNotifierProvider provider,
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
  String? get name => r'warningNotifierProvider';
}

/// Notifier for managing warning state with real-time updates
///
/// Copied from [WarningNotifier].
class WarningNotifierProvider extends AutoDisposeAsyncNotifierProviderImpl<
    WarningNotifier, List<Warning>> {
  /// Notifier for managing warning state with real-time updates
  ///
  /// Copied from [WarningNotifier].
  WarningNotifierProvider(
    String userId,
  ) : this._internal(
          () => WarningNotifier()..userId = userId,
          from: warningNotifierProvider,
          name: r'warningNotifierProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$warningNotifierHash,
          dependencies: WarningNotifierFamily._dependencies,
          allTransitiveDependencies:
              WarningNotifierFamily._allTransitiveDependencies,
          userId: userId,
        );

  WarningNotifierProvider._internal(
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
  FutureOr<List<Warning>> runNotifierBuild(
    covariant WarningNotifier notifier,
  ) {
    return notifier.build(
      userId,
    );
  }

  @override
  Override overrideWith(WarningNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: WarningNotifierProvider._internal(
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
  AutoDisposeAsyncNotifierProviderElement<WarningNotifier, List<Warning>>
      createElement() {
    return _WarningNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is WarningNotifierProvider && other.userId == userId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, userId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin WarningNotifierRef on AutoDisposeAsyncNotifierProviderRef<List<Warning>> {
  /// The parameter `userId` of this provider.
  String get userId;
}

class _WarningNotifierProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<WarningNotifier,
        List<Warning>> with WarningNotifierRef {
  _WarningNotifierProviderElement(super.provider);

  @override
  String get userId => (origin as WarningNotifierProvider).userId;
}

String _$currentUserWarningNotifierHash() =>
    r'a2672d38973d60d68dc83f0ddf783d7b9fb29b24';

/// Notifier for current user warnings
///
/// Copied from [CurrentUserWarningNotifier].
@ProviderFor(CurrentUserWarningNotifier)
final currentUserWarningNotifierProvider = AutoDisposeAsyncNotifierProvider<
    CurrentUserWarningNotifier, List<Warning>>.internal(
  CurrentUserWarningNotifier.new,
  name: r'currentUserWarningNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$currentUserWarningNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$CurrentUserWarningNotifier = AutoDisposeAsyncNotifier<List<Warning>>;
String _$warningStreamNotifierHash() =>
    r'2fb303bbb9d28f4c706a21066c70a6f134db1c12';

abstract class _$WarningStreamNotifier
    extends BuildlessAutoDisposeStreamNotifier<List<Warning>> {
  late final String userId;

  Stream<List<Warning>> build(
    String userId,
  );
}

/// Stream notifier for real-time warning updates
///
/// Copied from [WarningStreamNotifier].
@ProviderFor(WarningStreamNotifier)
const warningStreamNotifierProvider = WarningStreamNotifierFamily();

/// Stream notifier for real-time warning updates
///
/// Copied from [WarningStreamNotifier].
class WarningStreamNotifierFamily extends Family<AsyncValue<List<Warning>>> {
  /// Stream notifier for real-time warning updates
  ///
  /// Copied from [WarningStreamNotifier].
  const WarningStreamNotifierFamily();

  /// Stream notifier for real-time warning updates
  ///
  /// Copied from [WarningStreamNotifier].
  WarningStreamNotifierProvider call(
    String userId,
  ) {
    return WarningStreamNotifierProvider(
      userId,
    );
  }

  @override
  WarningStreamNotifierProvider getProviderOverride(
    covariant WarningStreamNotifierProvider provider,
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
  String? get name => r'warningStreamNotifierProvider';
}

/// Stream notifier for real-time warning updates
///
/// Copied from [WarningStreamNotifier].
class WarningStreamNotifierProvider
    extends AutoDisposeStreamNotifierProviderImpl<WarningStreamNotifier,
        List<Warning>> {
  /// Stream notifier for real-time warning updates
  ///
  /// Copied from [WarningStreamNotifier].
  WarningStreamNotifierProvider(
    String userId,
  ) : this._internal(
          () => WarningStreamNotifier()..userId = userId,
          from: warningStreamNotifierProvider,
          name: r'warningStreamNotifierProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$warningStreamNotifierHash,
          dependencies: WarningStreamNotifierFamily._dependencies,
          allTransitiveDependencies:
              WarningStreamNotifierFamily._allTransitiveDependencies,
          userId: userId,
        );

  WarningStreamNotifierProvider._internal(
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
  Stream<List<Warning>> runNotifierBuild(
    covariant WarningStreamNotifier notifier,
  ) {
    return notifier.build(
      userId,
    );
  }

  @override
  Override overrideWith(WarningStreamNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: WarningStreamNotifierProvider._internal(
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
  AutoDisposeStreamNotifierProviderElement<WarningStreamNotifier, List<Warning>>
      createElement() {
    return _WarningStreamNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is WarningStreamNotifierProvider && other.userId == userId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, userId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin WarningStreamNotifierRef
    on AutoDisposeStreamNotifierProviderRef<List<Warning>> {
  /// The parameter `userId` of this provider.
  String get userId;
}

class _WarningStreamNotifierProviderElement
    extends AutoDisposeStreamNotifierProviderElement<WarningStreamNotifier,
        List<Warning>> with WarningStreamNotifierRef {
  _WarningStreamNotifierProviderElement(super.provider);

  @override
  String get userId => (origin as WarningStreamNotifierProvider).userId;
}

String _$currentUserWarningStreamNotifierHash() =>
    r'77904c729c32340cf603f10fecf66628e08efa9c';

/// Stream notifier for current user warning updates
///
/// Copied from [CurrentUserWarningStreamNotifier].
@ProviderFor(CurrentUserWarningStreamNotifier)
final currentUserWarningStreamNotifierProvider =
    AutoDisposeStreamNotifierProvider<CurrentUserWarningStreamNotifier,
        List<Warning>>.internal(
  CurrentUserWarningStreamNotifier.new,
  name: r'currentUserWarningStreamNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$currentUserWarningStreamNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$CurrentUserWarningStreamNotifier
    = AutoDisposeStreamNotifier<List<Warning>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
