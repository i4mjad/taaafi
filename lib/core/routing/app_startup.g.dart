// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_startup.dart';

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
String _$appStartupHash() => r'db1e1475943091716de52dfa9f51496b830f3042';

/// See also [appStartup].
@ProviderFor(appStartup)
final appStartupProvider = FutureProvider<SecurityStartupResult>.internal(
  appStartup,
  name: r'appStartupProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$appStartupHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef AppStartupRef = FutureProviderRef<SecurityStartupResult>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
