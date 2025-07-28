// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'smart_alerts_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$smartAlertsServiceHash() =>
    r'7f025efe6e509ada76bbd6bbda6878cee8398b3c';

/// See also [smartAlertsService].
@ProviderFor(smartAlertsService)
final smartAlertsServiceProvider =
    AutoDisposeProvider<SmartAlertsService>.internal(
  smartAlertsService,
  name: r'smartAlertsServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$smartAlertsServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SmartAlertsServiceRef = AutoDisposeProviderRef<SmartAlertsService>;
String _$smartAlertsNotificationServiceHash() =>
    r'71e85614d463a1eec25174dc9714b61df2263ed2';

/// See also [smartAlertsNotificationService].
@ProviderFor(smartAlertsNotificationService)
final smartAlertsNotificationServiceProvider =
    AutoDisposeProvider<SmartAlertsNotificationService>.internal(
  smartAlertsNotificationService,
  name: r'smartAlertsNotificationServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$smartAlertsNotificationServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SmartAlertsNotificationServiceRef
    = AutoDisposeProviderRef<SmartAlertsNotificationService>;
String _$smartAlertSettingsHash() =>
    r'ce49d7c2e5f79bfae91807d4f15680d8d3724fa4';

/// See also [smartAlertSettings].
@ProviderFor(smartAlertSettings)
final smartAlertSettingsProvider =
    AutoDisposeStreamProvider<SmartAlertSettings?>.internal(
  smartAlertSettings,
  name: r'smartAlertSettingsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$smartAlertSettingsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SmartAlertSettingsRef
    = AutoDisposeStreamProviderRef<SmartAlertSettings?>;
String _$smartAlertEligibilityHash() =>
    r'a94c06fee4989851fc53731de5a5dea35a43d607';

/// See also [smartAlertEligibility].
@ProviderFor(smartAlertEligibility)
final smartAlertEligibilityProvider =
    AutoDisposeFutureProvider<SmartAlertEligibility>.internal(
  smartAlertEligibility,
  name: r'smartAlertEligibilityProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$smartAlertEligibilityHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SmartAlertEligibilityRef
    = AutoDisposeFutureProviderRef<SmartAlertEligibility>;
String _$nextAlertTimesHash() => r'c6d271441130797a4951853ae8c14ea29eb0a6f6';

/// See also [nextAlertTimes].
@ProviderFor(nextAlertTimes)
final nextAlertTimesProvider =
    AutoDisposeFutureProvider<Map<SmartAlertType, DateTime?>>.internal(
  nextAlertTimes,
  name: r'nextAlertTimesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$nextAlertTimesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef NextAlertTimesRef
    = AutoDisposeFutureProviderRef<Map<SmartAlertType, DateTime?>>;
String _$notificationsEnabledHash() =>
    r'5bac988503c0d2e99fc51bdfa9f5aee53d2e572b';

/// See also [notificationsEnabled].
@ProviderFor(notificationsEnabled)
final notificationsEnabledProvider = AutoDisposeFutureProvider<bool>.internal(
  notificationsEnabled,
  name: r'notificationsEnabledProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$notificationsEnabledHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef NotificationsEnabledRef = AutoDisposeFutureProviderRef<bool>;
String _$smartAlertsNotifierHash() =>
    r'b6f05572132ef33f3d2673284c5a606d76890735';

/// Notifier for managing smart alert settings
///
/// Copied from [SmartAlertsNotifier].
@ProviderFor(SmartAlertsNotifier)
final smartAlertsNotifierProvider = AutoDisposeAsyncNotifierProvider<
    SmartAlertsNotifier, SmartAlertSettings?>.internal(
  SmartAlertsNotifier.new,
  name: r'smartAlertsNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$smartAlertsNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SmartAlertsNotifier = AutoDisposeAsyncNotifier<SmartAlertSettings?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
