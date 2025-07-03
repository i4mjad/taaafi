// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_startup_simple.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$startupSecurityServiceHash() =>
    r'ba7d7f0e97889c8f7e455d3ea670a76466c72689';

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

typedef StartupSecurityServiceRef = ProviderRef<StartupSecurityService>;
String _$appStartupWithSecurityHash() =>
    r'70bdd37de8ba6b2752e1892cc5763b54642567e2';

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

typedef AppStartupWithSecurityRef = FutureProviderRef<SecurityStartupResult>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
