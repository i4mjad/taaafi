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
String _$userVerificationProgressHash() =>
    r'c7e155e1a7e80057408e764100dd4dde176663ad';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// Provider for user's verification progress (real-time stream)
///
/// Copied from [userVerificationProgress].
@ProviderFor(userVerificationProgress)
const userVerificationProgressProvider = UserVerificationProgressFamily();

/// Provider for user's verification progress (real-time stream)
///
/// Copied from [userVerificationProgress].
class UserVerificationProgressFamily
    extends Family<AsyncValue<ReferralVerificationModel?>> {
  /// Provider for user's verification progress (real-time stream)
  ///
  /// Copied from [userVerificationProgress].
  const UserVerificationProgressFamily();

  /// Provider for user's verification progress (real-time stream)
  ///
  /// Copied from [userVerificationProgress].
  UserVerificationProgressProvider call(
    String userId,
  ) {
    return UserVerificationProgressProvider(
      userId,
    );
  }

  @override
  UserVerificationProgressProvider getProviderOverride(
    covariant UserVerificationProgressProvider provider,
  ) {
    return call(
      provider.userId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'userVerificationProgressProvider';
}

/// Provider for user's verification progress (real-time stream)
///
/// Copied from [userVerificationProgress].
class UserVerificationProgressProvider
    extends AutoDisposeStreamProvider<ReferralVerificationModel?> {
  /// Provider for user's verification progress (real-time stream)
  ///
  /// Copied from [userVerificationProgress].
  UserVerificationProgressProvider(
    String userId,
  ) : this._internal(
          (ref) => userVerificationProgress(
            ref as UserVerificationProgressRef,
            userId,
          ),
          from: userVerificationProgressProvider,
          name: r'userVerificationProgressProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$userVerificationProgressHash,
          dependencies: UserVerificationProgressFamily._dependencies,
          allTransitiveDependencies:
              UserVerificationProgressFamily._allTransitiveDependencies,
          userId: userId,
        );

  UserVerificationProgressProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.userId,
  }) : super.internal();

  final String userId;

  @override
  Override overrideWith(
    Stream<ReferralVerificationModel?> Function(
            UserVerificationProgressRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: UserVerificationProgressProvider._internal(
        (ref) => create(ref as UserVerificationProgressRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        userId: userId,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<ReferralVerificationModel?> createElement() {
    return _UserVerificationProgressProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is UserVerificationProgressProvider && other.userId == userId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, userId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin UserVerificationProgressRef
    on AutoDisposeStreamProviderRef<ReferralVerificationModel?> {
  /// The parameter `userId` of this provider.
  String get userId;
}

class _UserVerificationProgressProviderElement
    extends AutoDisposeStreamProviderElement<ReferralVerificationModel?>
    with UserVerificationProgressRef {
  _UserVerificationProgressProviderElement(super.provider);

  @override
  String get userId => (origin as UserVerificationProgressProvider).userId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
