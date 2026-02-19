// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fort_state_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$fortStateStreamHash() => r'd8b36c311b95af1b131fb67c79c12cd58266da93';

/// Real-time stream of fort state changes.
///
/// Copied from [fortStateStream].
@ProviderFor(fortStateStream)
final fortStateStreamProvider = AutoDisposeStreamProvider<FortState>.internal(
  fortStateStream,
  name: r'fortStateStreamProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$fortStateStreamHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FortStateStreamRef = AutoDisposeStreamProviderRef<FortState>;
String _$fortStateNotifierHash() => r'985c594a5555adefa99db92a3fa79a2193c70f07';

/// See also [FortStateNotifier].
@ProviderFor(FortStateNotifier)
final fortStateNotifierProvider =
    AutoDisposeAsyncNotifierProvider<FortStateNotifier, FortState>.internal(
  FortStateNotifier.new,
  name: r'fortStateNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$fortStateNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$FortStateNotifier = AutoDisposeAsyncNotifier<FortState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
