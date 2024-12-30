// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ongoing_activity_details_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$ongoingActivityDetailsNotifierHash() =>
    r'77d59ca5c60ee135a1e6f00cfb802547c3f0e67a';

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

abstract class _$OngoingActivityDetailsNotifier
    extends BuildlessAutoDisposeAsyncNotifier<OngoingActivityDetails> {
  late final String activityId;

  FutureOr<OngoingActivityDetails> build(
    String activityId,
  );
}

/// See also [OngoingActivityDetailsNotifier].
@ProviderFor(OngoingActivityDetailsNotifier)
const ongoingActivityDetailsNotifierProvider =
    OngoingActivityDetailsNotifierFamily();

/// See also [OngoingActivityDetailsNotifier].
class OngoingActivityDetailsNotifierFamily
    extends Family<AsyncValue<OngoingActivityDetails>> {
  /// See also [OngoingActivityDetailsNotifier].
  const OngoingActivityDetailsNotifierFamily();

  /// See also [OngoingActivityDetailsNotifier].
  OngoingActivityDetailsNotifierProvider call(
    String activityId,
  ) {
    return OngoingActivityDetailsNotifierProvider(
      activityId,
    );
  }

  @override
  OngoingActivityDetailsNotifierProvider getProviderOverride(
    covariant OngoingActivityDetailsNotifierProvider provider,
  ) {
    return call(
      provider.activityId,
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
  String? get name => r'ongoingActivityDetailsNotifierProvider';
}

/// See also [OngoingActivityDetailsNotifier].
class OngoingActivityDetailsNotifierProvider
    extends AutoDisposeAsyncNotifierProviderImpl<OngoingActivityDetailsNotifier,
        OngoingActivityDetails> {
  /// See also [OngoingActivityDetailsNotifier].
  OngoingActivityDetailsNotifierProvider(
    String activityId,
  ) : this._internal(
          () => OngoingActivityDetailsNotifier()..activityId = activityId,
          from: ongoingActivityDetailsNotifierProvider,
          name: r'ongoingActivityDetailsNotifierProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$ongoingActivityDetailsNotifierHash,
          dependencies: OngoingActivityDetailsNotifierFamily._dependencies,
          allTransitiveDependencies:
              OngoingActivityDetailsNotifierFamily._allTransitiveDependencies,
          activityId: activityId,
        );

  OngoingActivityDetailsNotifierProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.activityId,
  }) : super.internal();

  final String activityId;

  @override
  FutureOr<OngoingActivityDetails> runNotifierBuild(
    covariant OngoingActivityDetailsNotifier notifier,
  ) {
    return notifier.build(
      activityId,
    );
  }

  @override
  Override overrideWith(OngoingActivityDetailsNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: OngoingActivityDetailsNotifierProvider._internal(
        () => create()..activityId = activityId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        activityId: activityId,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<OngoingActivityDetailsNotifier,
      OngoingActivityDetails> createElement() {
    return _OngoingActivityDetailsNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is OngoingActivityDetailsNotifierProvider &&
        other.activityId == activityId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, activityId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin OngoingActivityDetailsNotifierRef
    on AutoDisposeAsyncNotifierProviderRef<OngoingActivityDetails> {
  /// The parameter `activityId` of this provider.
  String get activityId;
}

class _OngoingActivityDetailsNotifierProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<
        OngoingActivityDetailsNotifier,
        OngoingActivityDetails> with OngoingActivityDetailsNotifierRef {
  _OngoingActivityDetailsNotifierProviderElement(super.provider);

  @override
  String get activityId =>
      (origin as OngoingActivityDetailsNotifierProvider).activityId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
