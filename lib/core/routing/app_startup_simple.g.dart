// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_startup_simple.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$startupSecurityServiceHash() =>
    r'723914e9e98aca13ebc2fc68845ee353c8db0187';

/// Provider for the startup security service
///
/// Copied from [startupSecurityService].
@ProviderFor(startupSecurityService)
final startupSecurityServiceProvider =
    Provider<StartupSecurityService>.internal(
  startupSecurityService,
  name: r'startupSecurityServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$startupSecurityServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef StartupSecurityServiceRef = ProviderRef<StartupSecurityService>;
String _$appStartupWithSecurityHash() =>
    r'0a8f0b02425c5e4e2f51190a52288a9eca55d2d7';

/// See also [appStartupWithSecurity].
@ProviderFor(appStartupWithSecurity)
final appStartupWithSecurityProvider =
    FutureProvider<SecurityStartupResult>.internal(
  appStartupWithSecurity,
  name: r'appStartupWithSecurityProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$appStartupWithSecurityHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AppStartupWithSecurityRef = FutureProviderRef<SecurityStartupResult>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
