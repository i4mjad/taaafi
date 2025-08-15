// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'activity_details_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$activityDetailsHash() => r'615e0739096d7f419dcb6bdb38ad6dacf908da60';

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

/// See also [activityDetails].
@ProviderFor(activityDetails)
const activityDetailsProvider = ActivityDetailsFamily();

/// See also [activityDetails].
class ActivityDetailsFamily extends Family<AsyncValue<Activity>> {
  /// See also [activityDetails].
  const ActivityDetailsFamily();

  /// See also [activityDetails].
  ActivityDetailsProvider call(
    String activityId,
  ) {
    return ActivityDetailsProvider(
      activityId,
    );
  }

  @override
  ActivityDetailsProvider getProviderOverride(
    covariant ActivityDetailsProvider provider,
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
  String? get name => r'activityDetailsProvider';
}

/// See also [activityDetails].
class ActivityDetailsProvider extends AutoDisposeFutureProvider<Activity> {
  /// See also [activityDetails].
  ActivityDetailsProvider(
    String activityId,
  ) : this._internal(
          (ref) => activityDetails(
            ref as ActivityDetailsRef,
            activityId,
          ),
          from: activityDetailsProvider,
          name: r'activityDetailsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$activityDetailsHash,
          dependencies: ActivityDetailsFamily._dependencies,
          allTransitiveDependencies:
              ActivityDetailsFamily._allTransitiveDependencies,
          activityId: activityId,
        );

  ActivityDetailsProvider._internal(
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
  Override overrideWith(
    FutureOr<Activity> Function(ActivityDetailsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ActivityDetailsProvider._internal(
        (ref) => create(ref as ActivityDetailsRef),
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
  AutoDisposeFutureProviderElement<Activity> createElement() {
    return _ActivityDetailsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ActivityDetailsProvider && other.activityId == activityId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, activityId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ActivityDetailsRef on AutoDisposeFutureProviderRef<Activity> {
  /// The parameter `activityId` of this provider.
  String get activityId;
}

class _ActivityDetailsProviderElement
    extends AutoDisposeFutureProviderElement<Activity> with ActivityDetailsRef {
  _ActivityDetailsProviderElement(super.provider);

  @override
  String get activityId => (origin as ActivityDetailsProvider).activityId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
