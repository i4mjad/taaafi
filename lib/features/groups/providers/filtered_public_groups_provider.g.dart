// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'filtered_public_groups_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$filteredPublicGroupsHash() =>
    r'b5e772e5ad9b932458edb93d971cec2fc997ef9d';

/// Provider that fetches public groups filtered by current user's gender
///
/// Copied from [filteredPublicGroups].
@ProviderFor(filteredPublicGroups)
final filteredPublicGroupsProvider =
    AutoDisposeStreamProvider<List<GroupEntity>>.internal(
  filteredPublicGroups,
  name: r'filteredPublicGroupsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$filteredPublicGroupsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FilteredPublicGroupsRef
    = AutoDisposeStreamProviderRef<List<GroupEntity>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
