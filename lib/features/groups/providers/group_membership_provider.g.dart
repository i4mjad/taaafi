// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_membership_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$groupMembershipNotifierHash() =>
    r'02d7f933ee9312fd90c257e68b164c9287fa7e44';

/// Provider for current user's group membership using real backend
///
/// Copied from [groupMembershipNotifier].
@ProviderFor(groupMembershipNotifier)
final groupMembershipNotifierProvider =
    AutoDisposeFutureProvider<GroupMembership?>.internal(
  groupMembershipNotifier,
  name: r'groupMembershipNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$groupMembershipNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef GroupMembershipNotifierRef
    = AutoDisposeFutureProviderRef<GroupMembership?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
