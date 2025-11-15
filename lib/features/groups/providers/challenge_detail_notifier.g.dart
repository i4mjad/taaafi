// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'challenge_detail_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$challengeDetailNotifierHash() =>
    r'8a50ad3c4a246bc638d6203ad71c98a4a4d9cf8e';

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

abstract class _$ChallengeDetailNotifier
    extends BuildlessAutoDisposeAsyncNotifier<ChallengeDetailState> {
  late final String challengeId;

  FutureOr<ChallengeDetailState> build(
    String challengeId,
  );
}

/// Notifier for managing challenge detail state
///
/// Copied from [ChallengeDetailNotifier].
@ProviderFor(ChallengeDetailNotifier)
const challengeDetailNotifierProvider = ChallengeDetailNotifierFamily();

/// Notifier for managing challenge detail state
///
/// Copied from [ChallengeDetailNotifier].
class ChallengeDetailNotifierFamily
    extends Family<AsyncValue<ChallengeDetailState>> {
  /// Notifier for managing challenge detail state
  ///
  /// Copied from [ChallengeDetailNotifier].
  const ChallengeDetailNotifierFamily();

  /// Notifier for managing challenge detail state
  ///
  /// Copied from [ChallengeDetailNotifier].
  ChallengeDetailNotifierProvider call(
    String challengeId,
  ) {
    return ChallengeDetailNotifierProvider(
      challengeId,
    );
  }

  @override
  ChallengeDetailNotifierProvider getProviderOverride(
    covariant ChallengeDetailNotifierProvider provider,
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
  String? get name => r'challengeDetailNotifierProvider';
}

/// Notifier for managing challenge detail state
///
/// Copied from [ChallengeDetailNotifier].
class ChallengeDetailNotifierProvider
    extends AutoDisposeAsyncNotifierProviderImpl<ChallengeDetailNotifier,
        ChallengeDetailState> {
  /// Notifier for managing challenge detail state
  ///
  /// Copied from [ChallengeDetailNotifier].
  ChallengeDetailNotifierProvider(
    String challengeId,
  ) : this._internal(
          () => ChallengeDetailNotifier()..challengeId = challengeId,
          from: challengeDetailNotifierProvider,
          name: r'challengeDetailNotifierProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$challengeDetailNotifierHash,
          dependencies: ChallengeDetailNotifierFamily._dependencies,
          allTransitiveDependencies:
              ChallengeDetailNotifierFamily._allTransitiveDependencies,
          challengeId: challengeId,
        );

  ChallengeDetailNotifierProvider._internal(
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
  FutureOr<ChallengeDetailState> runNotifierBuild(
    covariant ChallengeDetailNotifier notifier,
  ) {
    return notifier.build(
      challengeId,
    );
  }

  @override
  Override overrideWith(ChallengeDetailNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: ChallengeDetailNotifierProvider._internal(
        () => create()..challengeId = challengeId,
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
  AutoDisposeAsyncNotifierProviderElement<ChallengeDetailNotifier,
      ChallengeDetailState> createElement() {
    return _ChallengeDetailNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ChallengeDetailNotifierProvider &&
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
mixin ChallengeDetailNotifierRef
    on AutoDisposeAsyncNotifierProviderRef<ChallengeDetailState> {
  /// The parameter `challengeId` of this provider.
  String get challengeId;
}

class _ChallengeDetailNotifierProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<ChallengeDetailNotifier,
        ChallengeDetailState> with ChallengeDetailNotifierRef {
  _ChallengeDetailNotifierProviderElement(super.provider);

  @override
  String get challengeId =>
      (origin as ChallengeDetailNotifierProvider).challengeId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
