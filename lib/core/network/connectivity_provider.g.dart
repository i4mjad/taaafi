// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'connectivity_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$connectivityHash() => r'bc5ac7cbbc66e8357ccb71af393503e9e7ca7874';

/// Provides the singleton instance of [Connectivity].
///
/// Copied from [connectivity].
@ProviderFor(connectivity)
final connectivityProvider = Provider<Connectivity>.internal(
  connectivity,
  name: r'connectivityProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$connectivityHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef ConnectivityRef = ProviderRef<Connectivity>;
String _$networkStatusHash() => r'b9185e5afdfdfb86fbb3b755b5f671aed457e0a9';

/// Re-introduce the StreamProvider
///
/// Copied from [networkStatus].
@ProviderFor(networkStatus)
final networkStatusProvider = StreamProvider<bool>.internal(
  networkStatus,
  name: r'networkStatusProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$networkStatusHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef NetworkStatusRef = StreamProviderRef<bool>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
