import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_app_3/features/account/data/app_features_config.dart';
import 'package:reboot_app_3/features/account/providers/clean_ban_warning_providers.dart';
import 'package:reboot_app_3/features/account/data/models/ban.dart';

part 'direct_messaging_ban_providers.g.dart';

// ==================== DIRECT MESSAGING BAN CHECKS ====================

/// Check if current user can start a new conversation
/// Checks ban on 'start_conversation' feature
@riverpod
Future<bool> canStartConversation(Ref ref) async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    // Check if banned from starting conversations
    final canAccess = await ref.read(
      canCurrentUserAccessFeatureProvider(AppFeaturesConfig.startConversation).future,
    );

    return canAccess;
  } catch (e) {
    print('Error checking start conversation permission: $e');
    return false; // Fail safe
  }
}

/// Check if current user can send messages in direct messaging
/// Checks ban on 'sending_in_groups' feature (reused for DM)
@riverpod
Future<bool> canSendDirectMessage(Ref ref) async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    // Check if banned from sending messages
    final canAccess = await ref.read(
      canCurrentUserAccessFeatureProvider(AppFeaturesConfig.sendMessage).future,
    );

    return canAccess;
  } catch (e) {
    print('Error checking send message permission: $e');
    return false; // Fail safe
  }
}

/// Get ban details for starting conversations
@riverpod
Future<Ban?> startConversationBan(Ref ref) async {
  try {
    return await ref.read(
      currentUserFeatureBanProvider(AppFeaturesConfig.startConversation).future,
    );
  } catch (e) {
    print('Error getting start conversation ban: $e');
    return null;
  }
}

/// Get ban details for sending messages
@riverpod
Future<Ban?> sendDirectMessageBan(Ref ref) async {
  try {
    return await ref.read(
      currentUserFeatureBanProvider(AppFeaturesConfig.sendMessage).future,
    );
  } catch (e) {
    print('Error getting send message ban: $e');
    return null;
  }
}

/// Combined check: Can user access direct messaging at all?
/// Returns false if banned from either starting conversations OR sending messages
@riverpod
Future<bool> canAccessDirectMessaging(Ref ref) async {
  try {
    final canStart = await ref.read(canStartConversationProvider.future);
    final canSend = await ref.read(canSendDirectMessageProvider.future);

    // User needs both permissions to fully access DM
    return canStart && canSend;
  } catch (e) {
    print('Error checking direct messaging access: $e');
    return false; // Fail safe
  }
}

/// Get the most restrictive ban affecting direct messaging
/// Returns the ban that blocks DM access (if any)
@riverpod
Future<Ban?> directMessagingBan(Ref ref) async {
  try {
    // Check send message ban first (more restrictive for existing conversations)
    final sendBan = await ref.read(sendDirectMessageBanProvider.future);
    if (sendBan != null) return sendBan;

    // Then check start conversation ban
    final startBan = await ref.read(startConversationBanProvider.future);
    if (startBan != null) return startBan;

    return null;
  } catch (e) {
    print('Error getting direct messaging ban: $e');
    return null;
  }
}

/// Cached notifier for real-time DM access status
/// Auto-refreshes when user auth state changes
@riverpod
class DirectMessagingAccessNotifier extends _$DirectMessagingAccessNotifier {
  @override
  Future<DirectMessagingAccessStatus> build() async {
    // Listen to auth changes to auto-invalidate
    ref.listen(
      canAccessDirectMessagingProvider,
      (_, __) {
        // Auto-refresh when permissions change
      },
    );

    return await _checkAccess();
  }

  Future<DirectMessagingAccessStatus> _checkAccess() async {
    try {
      final canStart = await ref.read(canStartConversationProvider.future);
      final canSend = await ref.read(canSendDirectMessageProvider.future);
      final ban = await ref.read(directMessagingBanProvider.future);

      return DirectMessagingAccessStatus(
        canStartConversation: canStart,
        canSendMessage: canSend,
        isFullyAccessible: canStart && canSend,
        activeBan: ban,
      );
    } catch (e) {
      print('Error checking DM access status: $e');
      return DirectMessagingAccessStatus(
        canStartConversation: false,
        canSendMessage: false,
        isFullyAccessible: false,
        activeBan: null,
      );
    }
  }

  /// Manually refresh the access status
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _checkAccess());
  }
}

/// Data class for DM access status
class DirectMessagingAccessStatus {
  final bool canStartConversation;
  final bool canSendMessage;
  final bool isFullyAccessible;
  final Ban? activeBan;

  const DirectMessagingAccessStatus({
    required this.canStartConversation,
    required this.canSendMessage,
    required this.isFullyAccessible,
    this.activeBan,
  });

  /// Check if user is completely blocked from DM
  bool get isCompletelyBlocked => !canStartConversation && !canSendMessage;

  /// Check if user can only view but not send
  bool get isViewOnly => !canSendMessage && canStartConversation;

  /// Get appropriate error message key
  String get errorMessageKey {
    if (isCompletelyBlocked) {
      return 'direct-messaging-completely-restricted';
    } else if (!canStartConversation) {
      return 'start-conversation-restricted';
    } else if (!canSendMessage) {
      return 'send-message-restricted';
    }
    return 'feature-restricted';
  }

  DirectMessagingAccessStatus copyWith({
    bool? canStartConversation,
    bool? canSendMessage,
    bool? isFullyAccessible,
    Ban? activeBan,
  }) {
    return DirectMessagingAccessStatus(
      canStartConversation: canStartConversation ?? this.canStartConversation,
      canSendMessage: canSendMessage ?? this.canSendMessage,
      isFullyAccessible: isFullyAccessible ?? this.isFullyAccessible,
      activeBan: activeBan ?? this.activeBan,
    );
  }
}

