// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diaries_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$diariesServiceHash() => r'6d406616bc324d049e44c6ea236f1ea312cef3fb';

/// See also [diariesService].
@ProviderFor(diariesService)
final diariesServiceProvider = Provider<DiariesService>.internal(
  diariesService,
  name: r'diariesServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$diariesServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef DiariesServiceRef = ProviderRef<DiariesService>;
String _$diariesNotifierHash() => r'3fc960ab0c5dd2d5faee177cb1ffed7e65308dab';

/// See also [DiariesNotifier].
@ProviderFor(DiariesNotifier)
final diariesNotifierProvider =
    AutoDisposeAsyncNotifierProvider<DiariesNotifier, List<Diary>>.internal(
  DiariesNotifier.new,
  name: r'diariesNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$diariesNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$DiariesNotifier = AutoDisposeAsyncNotifier<List<Diary>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
