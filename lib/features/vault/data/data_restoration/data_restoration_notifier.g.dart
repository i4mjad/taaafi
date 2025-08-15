// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'data_restoration_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$dataRestorationRepositoryHash() =>
    r'821784f5a91c2048c3b95e1f03179952594a34fe';

/// Provider for the DataRestorationRepository
///
/// Copied from [dataRestorationRepository].
@ProviderFor(dataRestorationRepository)
final dataRestorationRepositoryProvider =
    Provider<DataRestorationRepository>.internal(
  dataRestorationRepository,
  name: r'dataRestorationRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$dataRestorationRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef DataRestorationRepositoryRef = ProviderRef<DataRestorationRepository>;
String _$dataRestorationServiceHash() =>
    r'b3586f696585f04abc4d2ad8d0a8834277a55de3';

/// Provider for the DataRestorationService
///
/// Copied from [dataRestorationService].
@ProviderFor(dataRestorationService)
final dataRestorationServiceProvider =
    Provider<DataRestorationService>.internal(
  dataRestorationService,
  name: r'dataRestorationServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$dataRestorationServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef DataRestorationServiceRef = ProviderRef<DataRestorationService>;
String _$shouldShowDataRestorationButtonHash() =>
    r'fe96b699479d50860f82f115f2cc496d48efe99a';

/// Provider to check if data restoration button should be shown
///
/// Copied from [shouldShowDataRestorationButton].
@ProviderFor(shouldShowDataRestorationButton)
final shouldShowDataRestorationButtonProvider =
    AutoDisposeFutureProvider<bool>.internal(
  shouldShowDataRestorationButton,
  name: r'shouldShowDataRestorationButtonProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$shouldShowDataRestorationButtonHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ShouldShowDataRestorationButtonRef = AutoDisposeFutureProviderRef<bool>;
String _$dataRestorationNotifierHash() =>
    r'58902e6e5b979908d98e060208c88267cae13cab';

/// Notifier for managing data restoration state
///
/// Copied from [DataRestorationNotifier].
@ProviderFor(DataRestorationNotifier)
final dataRestorationNotifierProvider = AutoDisposeNotifierProvider<
    DataRestorationNotifier, DataRestorationState>.internal(
  DataRestorationNotifier.new,
  name: r'dataRestorationNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$dataRestorationNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$DataRestorationNotifier = AutoDisposeNotifier<DataRestorationState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
