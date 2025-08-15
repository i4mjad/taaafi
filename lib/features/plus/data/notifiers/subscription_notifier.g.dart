// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$hasActiveSubscriptionHash() =>
    r'5572df4916165f48c879e113a2b9f9fac448fe36';

/// See also [hasActiveSubscription].
@ProviderFor(hasActiveSubscription)
final hasActiveSubscriptionProvider = AutoDisposeProvider<bool>.internal(
  hasActiveSubscription,
  name: r'hasActiveSubscriptionProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$hasActiveSubscriptionHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef HasActiveSubscriptionRef = AutoDisposeProviderRef<bool>;
String _$isPremiumAnalyticsAvailableHash() =>
    r'1e709839b82d9876e332264630cd6ae2a1da09cb';

/// See also [isPremiumAnalyticsAvailable].
@ProviderFor(isPremiumAnalyticsAvailable)
final isPremiumAnalyticsAvailableProvider =
    AutoDisposeFutureProvider<bool>.internal(
  isPremiumAnalyticsAvailable,
  name: r'isPremiumAnalyticsAvailableProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$isPremiumAnalyticsAvailableHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef IsPremiumAnalyticsAvailableRef = AutoDisposeFutureProviderRef<bool>;
String _$availablePackagesHash() => r'851247acc24df055dff00eb4dc6e4bbba8725b67';

/// See also [availablePackages].
@ProviderFor(availablePackages)
final availablePackagesProvider =
    AutoDisposeFutureProvider<List<Package>>.internal(
  availablePackages,
  name: r'availablePackagesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$availablePackagesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AvailablePackagesRef = AutoDisposeFutureProviderRef<List<Package>>;
String _$subscriptionNotifierHash() =>
    r'2a975e71ee34d033595a9a99c78fee3a99675088';

/// See also [SubscriptionNotifier].
@ProviderFor(SubscriptionNotifier)
final subscriptionNotifierProvider = AutoDisposeAsyncNotifierProvider<
    SubscriptionNotifier, SubscriptionInfo>.internal(
  SubscriptionNotifier.new,
  name: r'subscriptionNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$subscriptionNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SubscriptionNotifier = AutoDisposeAsyncNotifier<SubscriptionInfo>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
