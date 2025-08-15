// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diaries_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$diariesServiceHash() => r'e6aeed0fa4a6f6466d83688a626f69b9944f8de4';

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

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef DiariesServiceRef = ProviderRef<DiariesService>;
String _$diariesNotifierHash() => r'656975b929914fff1c8eed725e0013b578493e8e';

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
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
