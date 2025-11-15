// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'challenges_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$challengesNotifierHash() =>
    r'eca4d8b4e1b3980b935a985ad4c12cd115ed25d2';

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

abstract class _$ChallengesNotifier
    extends BuildlessAutoDisposeAsyncNotifier<ChallengesState> {
  late final String groupId;

  FutureOr<ChallengesState> build(
    String groupId,
  );
}

/// Notifier for managing challenges list state
///
/// Copied from [ChallengesNotifier].
@ProviderFor(ChallengesNotifier)
const challengesNotifierProvider = ChallengesNotifierFamily();

/// Notifier for managing challenges list state
///
/// Copied from [ChallengesNotifier].
class ChallengesNotifierFamily extends Family<AsyncValue<ChallengesState>> {
  /// Notifier for managing challenges list state
  ///
  /// Copied from [ChallengesNotifier].
  const ChallengesNotifierFamily();

  /// Notifier for managing challenges list state
  ///
  /// Copied from [ChallengesNotifier].
  ChallengesNotifierProvider call(
    String groupId,
  ) {
    return ChallengesNotifierProvider(
      groupId,
    );
  }

  @override
  ChallengesNotifierProvider getProviderOverride(
    covariant ChallengesNotifierProvider provider,
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
  String? get name => r'challengesNotifierProvider';
}

/// Notifier for managing challenges list state
///
/// Copied from [ChallengesNotifier].
class ChallengesNotifierProvider extends AutoDisposeAsyncNotifierProviderImpl<
    ChallengesNotifier, ChallengesState> {
  /// Notifier for managing challenges list state
  ///
  /// Copied from [ChallengesNotifier].
  ChallengesNotifierProvider(
    String groupId,
  ) : this._internal(
          () => ChallengesNotifier()..groupId = groupId,
          from: challengesNotifierProvider,
          name: r'challengesNotifierProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$challengesNotifierHash,
          dependencies: ChallengesNotifierFamily._dependencies,
          allTransitiveDependencies:
              ChallengesNotifierFamily._allTransitiveDependencies,
          groupId: groupId,
        );

  ChallengesNotifierProvider._internal(
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
  FutureOr<ChallengesState> runNotifierBuild(
    covariant ChallengesNotifier notifier,
  ) {
    return notifier.build(
      groupId,
    );
  }

  @override
  Override overrideWith(ChallengesNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: ChallengesNotifierProvider._internal(
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
  AutoDisposeAsyncNotifierProviderElement<ChallengesNotifier, ChallengesState>
      createElement() {
    return _ChallengesNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ChallengesNotifierProvider && other.groupId == groupId;
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
mixin ChallengesNotifierRef
    on AutoDisposeAsyncNotifierProviderRef<ChallengesState> {
  /// The parameter `groupId` of this provider.
  String get groupId;
}

class _ChallengesNotifierProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<ChallengesNotifier,
        ChallengesState> with ChallengesNotifierRef {
  _ChallengesNotifierProviderElement(super.provider);

  @override
  String get groupId => (origin as ChallengesNotifierProvider).groupId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
