// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$hasActiveSubscriptionHash() =>
    r'1508f52259a508c129c04b6038326e2504d04b7e';

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
    r'725aed4e99833666e6ed9b17720b8f7dc2e5daef';

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
String _$availablePackagesHash() => r'728ef18ed82f021d4386eec4e2681074344574f2';

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
    r'95d15559007bae4ad5f40637d03484f8fdb283f4';

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
