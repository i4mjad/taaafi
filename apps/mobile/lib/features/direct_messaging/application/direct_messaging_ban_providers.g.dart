// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'direct_messaging_ban_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$canStartConversationHash() =>
    r'4b29b2c497e3f4efb21326b798d1ea9c88c8374b';

/// Check if current user can start a new conversation
/// Checks ban on 'start_conversation' feature
///
/// Copied from [canStartConversation].
@ProviderFor(canStartConversation)
final canStartConversationProvider = AutoDisposeFutureProvider<bool>.internal(
  canStartConversation,
  name: r'canStartConversationProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$canStartConversationHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CanStartConversationRef = AutoDisposeFutureProviderRef<bool>;
String _$canSendDirectMessageHash() =>
    r'7d82d81248f1ea4ee3eb9c5780bcd3bbdacdcaa5';

/// Check if current user can send messages in direct messaging
/// Checks ban on 'sending_in_groups' feature (reused for DM)
///
/// Copied from [canSendDirectMessage].
@ProviderFor(canSendDirectMessage)
final canSendDirectMessageProvider = AutoDisposeFutureProvider<bool>.internal(
  canSendDirectMessage,
  name: r'canSendDirectMessageProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$canSendDirectMessageHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CanSendDirectMessageRef = AutoDisposeFutureProviderRef<bool>;
String _$startConversationBanHash() =>
    r'4656560f0c6bda313cee9b0ac46851c1cf29cb37';

/// Get ban details for starting conversations
///
/// Copied from [startConversationBan].
@ProviderFor(startConversationBan)
final startConversationBanProvider = AutoDisposeFutureProvider<Ban?>.internal(
  startConversationBan,
  name: r'startConversationBanProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$startConversationBanHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef StartConversationBanRef = AutoDisposeFutureProviderRef<Ban?>;
String _$sendDirectMessageBanHash() =>
    r'b71eb21c966ff5458d0e9f769e047c8cb245318c';

/// Get ban details for sending messages
///
/// Copied from [sendDirectMessageBan].
@ProviderFor(sendDirectMessageBan)
final sendDirectMessageBanProvider = AutoDisposeFutureProvider<Ban?>.internal(
  sendDirectMessageBan,
  name: r'sendDirectMessageBanProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$sendDirectMessageBanHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SendDirectMessageBanRef = AutoDisposeFutureProviderRef<Ban?>;
String _$canAccessDirectMessagingHash() =>
    r'f326cd98faad2b0fcafdb948742a1e98d8da06eb';

/// Combined check: Can user access direct messaging at all?
/// Returns false if banned from either starting conversations OR sending messages
///
/// Copied from [canAccessDirectMessaging].
@ProviderFor(canAccessDirectMessaging)
final canAccessDirectMessagingProvider =
    AutoDisposeFutureProvider<bool>.internal(
  canAccessDirectMessaging,
  name: r'canAccessDirectMessagingProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$canAccessDirectMessagingHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CanAccessDirectMessagingRef = AutoDisposeFutureProviderRef<bool>;
String _$directMessagingBanHash() =>
    r'898b0a077fbe613a44f4f7e5f058394b90437f06';

/// Get the most restrictive ban affecting direct messaging
/// Returns the ban that blocks DM access (if any)
///
/// Copied from [directMessagingBan].
@ProviderFor(directMessagingBan)
final directMessagingBanProvider = AutoDisposeFutureProvider<Ban?>.internal(
  directMessagingBan,
  name: r'directMessagingBanProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$directMessagingBanHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef DirectMessagingBanRef = AutoDisposeFutureProviderRef<Ban?>;
String _$directMessagingAccessNotifierHash() =>
    r'5d8a776297ca4560777801228645e510c253927e';

/// Cached notifier for real-time DM access status
/// Auto-refreshes when user auth state changes
///
/// Copied from [DirectMessagingAccessNotifier].
@ProviderFor(DirectMessagingAccessNotifier)
final directMessagingAccessNotifierProvider = AutoDisposeAsyncNotifierProvider<
    DirectMessagingAccessNotifier, DirectMessagingAccessStatus>.internal(
  DirectMessagingAccessNotifier.new,
  name: r'directMessagingAccessNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$directMessagingAccessNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$DirectMessagingAccessNotifier
    = AutoDisposeAsyncNotifier<DirectMessagingAccessStatus>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
