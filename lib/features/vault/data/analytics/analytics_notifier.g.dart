// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'analytics_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$premiumAnalyticsServiceHash() =>
    r'15e1098059e2fe3a741172c8d56c5677516e4b69';

/// See also [premiumAnalyticsService].
@ProviderFor(premiumAnalyticsService)
final premiumAnalyticsServiceProvider =
    AutoDisposeProvider<PremiumAnalyticsService>.internal(
  premiumAnalyticsService,
  name: r'premiumAnalyticsServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$premiumAnalyticsServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PremiumAnalyticsServiceRef
    = AutoDisposeProviderRef<PremiumAnalyticsService>;
String _$heatMapDataHash() => r'f4905e333c7206e4259c9f283ce2d04da3ffee96';

/// See also [heatMapData].
@ProviderFor(heatMapData)
final heatMapDataProvider =
    AutoDisposeFutureProvider<List<AnalyticsFollowUp>>.internal(
  heatMapData,
  name: r'heatMapDataProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$heatMapDataHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef HeatMapDataRef = AutoDisposeFutureProviderRef<List<AnalyticsFollowUp>>;
String _$streakAveragesHash() => r'5842b65eab1475414091b829fc2f37b287a551c3';

/// See also [streakAverages].
@ProviderFor(streakAverages)
final streakAveragesProvider =
    AutoDisposeFutureProvider<Map<String, double>>.internal(
  streakAverages,
  name: r'streakAveragesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$streakAveragesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef StreakAveragesRef = AutoDisposeFutureProviderRef<Map<String, double>>;
String _$triggerRadarDataHash() => r'6c68623ab6ef1ca49ad7fa6f86b79984b854f359';

/// See also [triggerRadarData].
@ProviderFor(triggerRadarData)
final triggerRadarDataProvider =
    AutoDisposeFutureProvider<Map<String, int>>.internal(
  triggerRadarData,
  name: r'triggerRadarDataProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$triggerRadarDataHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef TriggerRadarDataRef = AutoDisposeFutureProviderRef<Map<String, int>>;
String _$riskClockDataHash() => r'c24ea7e437ee9e01b67f64af1be1872a869a685e';

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

/// See also [riskClockData].
@ProviderFor(riskClockData)
const riskClockDataProvider = RiskClockDataFamily();

/// See also [riskClockData].
class RiskClockDataFamily extends Family<AsyncValue<List<int>>> {
  /// See also [riskClockData].
  const RiskClockDataFamily();

  /// See also [riskClockData].
  RiskClockDataProvider call([
    FollowUpType? filterType,
  ]) {
    return RiskClockDataProvider(
      filterType,
    );
  }

  @override
  RiskClockDataProvider getProviderOverride(
    covariant RiskClockDataProvider provider,
  ) {
    return call(
      provider.filterType,
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
  String? get name => r'riskClockDataProvider';
}

/// See also [riskClockData].
class RiskClockDataProvider extends AutoDisposeFutureProvider<List<int>> {
  /// See also [riskClockData].
  RiskClockDataProvider([
    FollowUpType? filterType,
  ]) : this._internal(
          (ref) => riskClockData(
            ref as RiskClockDataRef,
            filterType,
          ),
          from: riskClockDataProvider,
          name: r'riskClockDataProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$riskClockDataHash,
          dependencies: RiskClockDataFamily._dependencies,
          allTransitiveDependencies:
              RiskClockDataFamily._allTransitiveDependencies,
          filterType: filterType,
        );

  RiskClockDataProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.filterType,
  }) : super.internal();

  final FollowUpType? filterType;

  @override
  Override overrideWith(
    FutureOr<List<int>> Function(RiskClockDataRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: RiskClockDataProvider._internal(
        (ref) => create(ref as RiskClockDataRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        filterType: filterType,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<int>> createElement() {
    return _RiskClockDataProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is RiskClockDataProvider && other.filterType == filterType;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, filterType.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin RiskClockDataRef on AutoDisposeFutureProviderRef<List<int>> {
  /// The parameter `filterType` of this provider.
  FollowUpType? get filterType;
}

class _RiskClockDataProviderElement
    extends AutoDisposeFutureProviderElement<List<int>> with RiskClockDataRef {
  _RiskClockDataProviderElement(super.provider);

  @override
  FollowUpType? get filterType => (origin as RiskClockDataProvider).filterType;
}

String _$moodCorrelationDataHash() =>
    r'54d0472008435317b4ecb53a950e7e832088b91c';

/// See also [moodCorrelationData].
@ProviderFor(moodCorrelationData)
final moodCorrelationDataProvider =
    AutoDisposeFutureProvider<MoodCorrelationData>.internal(
  moodCorrelationData,
  name: r'moodCorrelationDataProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$moodCorrelationDataHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef MoodCorrelationDataRef
    = AutoDisposeFutureProviderRef<MoodCorrelationData>;
String _$cachedMoodCorrelationDataHash() =>
    r'e89172378f9abd74833dd572dbcbb25843aa80c0';

/// See also [cachedMoodCorrelationData].
@ProviderFor(cachedMoodCorrelationData)
final cachedMoodCorrelationDataProvider =
    FutureProvider<MoodCorrelationData>.internal(
  cachedMoodCorrelationData,
  name: r'cachedMoodCorrelationDataProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$cachedMoodCorrelationDataHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CachedMoodCorrelationDataRef = FutureProviderRef<MoodCorrelationData>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
