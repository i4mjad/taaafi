// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'usage_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$monthlyUsageSummariesHash() =>
    r'9478e3fa925787906eb556cf3a9a7ebd366b8d85';

/// Historical usage summaries for the current month (free tier).
///
/// Copied from [monthlyUsageSummaries].
@ProviderFor(monthlyUsageSummaries)
final monthlyUsageSummariesProvider =
    AutoDisposeFutureProvider<List<UsageSummary>>.internal(
  monthlyUsageSummaries,
  name: r'monthlyUsageSummariesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$monthlyUsageSummariesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef MonthlyUsageSummariesRef
    = AutoDisposeFutureProviderRef<List<UsageSummary>>;
String _$usagePermissionHash() => r'3ea1b76a6fbcca70584d845c503435f4b67a2f43';

/// Whether the user has granted usage access permission.
///
/// Copied from [UsagePermission].
@ProviderFor(UsagePermission)
final usagePermissionProvider =
    AutoDisposeAsyncNotifierProvider<UsagePermission, bool>.internal(
  UsagePermission.new,
  name: r'usagePermissionProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$usagePermissionHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$UsagePermission = AutoDisposeAsyncNotifier<bool>;
String _$usageNotifierHash() => r'edeac2b551e70f052483a338378f0720e4f3f322';

/// Today's usage data — fetches from native and persists to Firestore.
///
/// Copied from [UsageNotifier].
@ProviderFor(UsageNotifier)
final usageNotifierProvider =
    AutoDisposeAsyncNotifierProvider<UsageNotifier, UsageSummary>.internal(
  UsageNotifier.new,
  name: r'usageNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$usageNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$UsageNotifier = AutoDisposeAsyncNotifier<UsageSummary>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
