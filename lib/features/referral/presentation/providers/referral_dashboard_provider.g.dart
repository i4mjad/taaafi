// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'referral_dashboard_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$currentUserIdHash() => r'b575e143ac1ee8cf8f1271405e64bea0eb69034e';

/// Provider for current user's ID
///
/// Copied from [currentUserId].
@ProviderFor(currentUserId)
final currentUserIdProvider = AutoDisposeProvider<String?>.internal(
  currentUserId,
  name: r'currentUserIdProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$currentUserIdHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CurrentUserIdRef = AutoDisposeProviderRef<String?>;
String _$userReferralCodeHash() => r'00836b865a52a9201ca63f2a1047a799c1cd9650';

/// Provider for user's referral code
///
/// Copied from [userReferralCode].
@ProviderFor(userReferralCode)
final userReferralCodeProvider =
    AutoDisposeFutureProvider<ReferralCodeModel?>.internal(
  userReferralCode,
  name: r'userReferralCodeProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$userReferralCodeHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef UserReferralCodeRef = AutoDisposeFutureProviderRef<ReferralCodeModel?>;
String _$referralStatsHash() => r'8cb69d95ff340ed2a15b40a509d40cc572e50014';

/// Provider for referral stats
///
/// Copied from [referralStats].
@ProviderFor(referralStats)
final referralStatsProvider =
    AutoDisposeFutureProvider<ReferralStatsModel?>.internal(
  referralStats,
  name: r'referralStatsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$referralStatsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ReferralStatsRef = AutoDisposeFutureProviderRef<ReferralStatsModel?>;
String _$referredUsersHash() => r'928447bf31e8ef4ae0ac85f841a7bde99e3ca72e';

/// Provider for referred users list
///
/// Copied from [referredUsers].
@ProviderFor(referredUsers)
final referredUsersProvider =
    AutoDisposeFutureProvider<List<ReferralVerificationModel>>.internal(
  referredUsers,
  name: r'referredUsersProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$referredUsersHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ReferredUsersRef
    = AutoDisposeFutureProviderRef<List<ReferralVerificationModel>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
