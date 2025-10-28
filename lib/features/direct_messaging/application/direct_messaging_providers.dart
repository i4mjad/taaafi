import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entities/direct_message_entity.dart';
import '../domain/entities/direct_conversation_entity.dart';
import '../domain/entities/user_block_entity.dart';
import '../data/datasources/direct_messages_firestore_datasource.dart';
import '../data/datasources/conversations_firestore_datasource.dart';
import '../data/datasources/user_blocks_firestore_datasource.dart';
import '../data/repositories/direct_chat_repository.dart';
import '../data/repositories/conversations_repository.dart';
import '../data/repositories/user_blocks_repository.dart';
import '../../community/presentation/providers/community_providers_new.dart';
import '../data/models/direct_conversation_model.dart';
import '../../authentication/providers/user_provider.dart';

part 'direct_messaging_providers.g.dart';

// ==================== DATA SOURCE PROVIDERS ====================

@riverpod
DirectMessagesDataSource directMessagesDataSource(Ref ref) {
  return DirectMessagesFirestoreDataSource(FirebaseFirestore.instance);
}

@riverpod
ConversationsDataSource conversationsDataSource(Ref ref) {
  return ConversationsFirestoreDataSource(FirebaseFirestore.instance);
}

@riverpod
UserBlocksDataSource userBlocksDataSource(Ref ref) {
  return UserBlocksFirestoreDataSource(FirebaseFirestore.instance);
}

// ==================== REPOSITORY PROVIDERS ====================

@riverpod
DirectChatRepository directChatRepository(Ref ref) {
  final dataSource = ref.watch(directMessagesDataSourceProvider);
  return DirectChatRepositoryFactory.create(dataSource);
}

@riverpod
ConversationsRepository conversationsRepository(Ref ref) {
  final dataSource = ref.watch(conversationsDataSourceProvider);
  return ConversationsRepositoryFactory.create(dataSource);
}

@riverpod
UserBlocksRepository userBlocksRepository(Ref ref) {
  final dataSource = ref.watch(userBlocksDataSourceProvider);
  return UserBlocksRepositoryFactory.create(dataSource);
}

// ==================== MESSAGE STREAM PROVIDERS ====================

/// Provider for watching messages in a specific conversation
@riverpod
Stream<List<DirectMessageEntity>> directChatMessages(
  Ref ref,
  String conversationId,
) {
  final repository = ref.watch(directChatRepositoryProvider);

  return repository.watchMessages(conversationId).handleError((error) {
    print(
        'Error in directChatMessages provider for conversation $conversationId: $error');
    return <DirectMessageEntity>[];
  });
}

// ==================== CONVERSATION STREAM PROVIDERS ====================

/// Provider for watching user's conversations
@riverpod
Stream<List<DirectConversationEntity>> userConversations(Ref ref) {
  final currentProfile = ref.watch(currentCommunityProfileProvider);

  return currentProfile.when(
    data: (profile) {
      if (profile == null) {
        return Stream.value(<DirectConversationEntity>[]);
      }

      final repository = ref.watch(conversationsRepositoryProvider);
      return repository.watchUserConversations(profile.id);
    },
    loading: () => Stream.value(<DirectConversationEntity>[]),
    error: (_, __) => Stream.value(<DirectConversationEntity>[]),
  );
}

// ==================== CONVERSATION MANAGEMENT ====================

/// Provider to find or create a conversation
@riverpod
Future<DirectConversationEntity?> findOrCreateConversation(
  Ref ref,
  String otherCpId,
) async {
  try {
    final currentProfile =
        await ref.read(currentCommunityProfileProvider.future);
    if (currentProfile == null) {
      throw Exception('Community profile required');
    }

    final repository = ref.read(conversationsRepositoryProvider);
    final conversation = await repository.findOrCreateConversation(
      currentProfile.id,
      otherCpId,
    );

    return conversation;
  } catch (error) {
    print('Error finding/creating conversation: $error');
    rethrow;
  }
}

// ==================== BLOCK PROVIDERS ====================

/// Check if I have blocked a user
@riverpod
Future<bool> didIBlockUser(Ref ref, String otherCpId) async {
  try {
    final currentProfile =
        await ref.read(currentCommunityProfileProvider.future);
    if (currentProfile == null) return false;

    final repository = ref.read(userBlocksRepositoryProvider);
    return await repository.isBlocked(currentProfile.id, otherCpId);
  } catch (error) {
    print('Error checking if user is blocked: $error');
    return false;
  }
}

/// Check if another user has blocked me
@riverpod
Future<bool> hasUserBlockedMe(Ref ref, String otherCpId) async {
  try {
    final currentProfile =
        await ref.read(currentCommunityProfileProvider.future);
    if (currentProfile == null) return false;

    final repository = ref.read(userBlocksRepositoryProvider);
    return await repository.hasBlockedMe(currentProfile.id, otherCpId);
  } catch (error) {
    print('Error checking if blocked by user: $error');
    return false;
  }
}

/// Check if there's any block between me and another user (either direction)
@riverpod
Future<bool> isAnyBlockBetween(Ref ref, String otherCpId) async {
  final iBlocked = await ref.read(didIBlockUserProvider(otherCpId).future);
  final blockedMe = await ref.read(hasUserBlockedMeProvider(otherCpId).future);
  return iBlocked || blockedMe;
}

// ==================== ACCESS CONTROL ====================

/// Provider to check if user can access a direct chat conversation
@riverpod
Future<bool> canAccessDirectChat(Ref ref, String conversationId) async {
  try {
    final currentProfile =
        await ref.read(currentCommunityProfileProvider.future);
    if (currentProfile == null) return false;

    // Get conversation to check if user is a participant
    final repository = ref.read(conversationsRepositoryProvider);
    final conversationDoc = await FirebaseFirestore.instance
        .collection('direct_conversations')
        .doc(conversationId)
        .get();

    if (!conversationDoc.exists) return false;

    final conversation = DirectConversationModel.fromFirestore(conversationDoc);

    // Check if user is a participant
    if (!conversation.participantCpIds.contains(currentProfile.id)) {
      return false;
    }

    // Check if conversation is deleted for this user
    if (conversation.isDeletedFor(currentProfile.id)) {
      return false;
    }

    return true;
  } catch (error) {
    print('Error checking direct chat access: $error');
    return false;
  }
}

// ==================== DIRECT CHAT CONTROLLER ====================

/// Controller for sending messages in direct chat
@riverpod
class DirectChatController extends _$DirectChatController {
  @override
  bool build() => false; // Busy state

  /// Send a message
  Future<void> send(
    String conversationId,
    String body, {
    String? replyToMessageId,
    String? quotedPreview,
  }) async {
    if (state) {
      throw Exception('Message send already in progress');
    }

    try {
      state = true;

      // Get current user's community profile
      final currentProfile =
          await ref.read(currentCommunityProfileProvider.future);
      if (currentProfile == null) {
        throw Exception('Community profile required to send messages');
      }

      final repository = ref.read(directChatRepositoryProvider);

      // Create message entity
      final message = DirectMessageEntity(
        id: '',
        conversationId: conversationId,
        senderCpId: currentProfile.id,
        body: body.trim(),
        replyToMessageId: replyToMessageId,
        quotedPreview: quotedPreview,
        createdAt: DateTime.now(),
        moderation: const ModerationStatus(
          status: ModerationStatusType.approved,
        ),
      );

      await repository.sendMessage(message);

      // Update conversation last activity
      final conversationsRepo = ref.read(conversationsRepositoryProvider);
      await conversationsRepo.updateLastActivity(
        conversationId,
        body.trim(),
      );

      // Clear cache to force refresh
      repository.clearCache(conversationId);

      print('Message sent successfully to conversation $conversationId');
    } catch (error) {
      print('Error sending message: $error');
      rethrow;
    } finally {
      state = false;
    }
  }

  /// Delete a message
  Future<void> deleteMessage(String conversationId, String messageId) async {
    try {
      final repository = ref.read(directChatRepositoryProvider);
      await repository.deleteMessage(conversationId, messageId);
      repository.clearCache(conversationId);
    } catch (error) {
      print('Error deleting message: $error');
      rethrow;
    }
  }
}

// ==================== CONVERSATION ACTIONS CONTROLLER ====================

/// Controller for conversation actions (mute, archive, delete, etc.)
@riverpod
class ConversationActionsController extends _$ConversationActionsController {
  @override
  bool build() => false; // Busy state

  Future<void> markAsRead(String conversationId) async {
    try {
      final currentProfile =
          await ref.read(currentCommunityProfileProvider.future);
      if (currentProfile == null) return;

      final repository = ref.read(conversationsRepositoryProvider);
      await repository.markAsRead(conversationId, currentProfile.id);
    } catch (error) {
      print('Error marking conversation as read: $error');
      rethrow;
    }
  }

  Future<void> muteConversation(String conversationId) async {
    try {
      final currentProfile =
          await ref.read(currentCommunityProfileProvider.future);
      if (currentProfile == null) return;

      final repository = ref.read(conversationsRepositoryProvider);
      await repository.muteConversation(conversationId, currentProfile.id);
    } catch (error) {
      print('Error muting conversation: $error');
      rethrow;
    }
  }

  Future<void> unmuteConversation(String conversationId) async {
    try {
      final currentProfile =
          await ref.read(currentCommunityProfileProvider.future);
      if (currentProfile == null) return;

      final repository = ref.read(conversationsRepositoryProvider);
      await repository.unmuteConversation(conversationId, currentProfile.id);
    } catch (error) {
      print('Error unmuting conversation: $error');
      rethrow;
    }
  }

  Future<void> deleteConversation(String conversationId) async {
    try {
      final currentProfile =
          await ref.read(currentCommunityProfileProvider.future);
      if (currentProfile == null) return;

      final repository = ref.read(conversationsRepositoryProvider);
      await repository.deleteConversationFor(conversationId, currentProfile.id);
    } catch (error) {
      print('Error deleting conversation: $error');
      rethrow;
    }
  }
}

// ==================== BLOCK CONTROLLER ====================

/// Controller for blocking/unblocking users
@riverpod
class BlockController extends _$BlockController {
  @override
  bool build() => false; // Busy state

  Future<void> blockUser(String blockedCpId, String blockedUid,
      {String? reason}) async {
    if (state) return;

    try {
      state = true;

      final currentProfile =
          await ref.read(currentCommunityProfileProvider.future);
      if (currentProfile == null) {
        throw Exception('Community profile required');
      }

      // Get current user UID
      final currentUser = await ref.read(userNotifierProvider.future);
      if (currentUser == null) {
        throw Exception('User must be authenticated');
      }

      final blockId =
          UserBlockEntity.generateBlockId(currentProfile.id, blockedCpId);
      final block = UserBlockEntity(
        id: blockId,
        blockerUid: currentUser.uid,
        blockerCpId: currentProfile.id,
        blockedUid: blockedUid,
        blockedCpId: blockedCpId,
        createdAt: DateTime.now(),
        reason: reason,
      );

      final repository = ref.read(userBlocksRepositoryProvider);
      await repository.blockUser(block);

      // Invalidate related providers
      ref.invalidate(didIBlockUserProvider(blockedCpId));
      ref.invalidate(isAnyBlockBetweenProvider(blockedCpId));

      print('User blocked successfully: $blockedCpId');
    } catch (error) {
      print('Error blocking user: $error');
      rethrow;
    } finally {
      state = false;
    }
  }

  Future<void> unblockUser(String blockedCpId) async {
    if (state) return;

    try {
      state = true;

      final currentProfile =
          await ref.read(currentCommunityProfileProvider.future);
      if (currentProfile == null) {
        throw Exception('Community profile required');
      }

      final repository = ref.read(userBlocksRepositoryProvider);
      await repository.unblockUser(currentProfile.id, blockedCpId);

      // Invalidate related providers
      ref.invalidate(didIBlockUserProvider(blockedCpId));
      ref.invalidate(isAnyBlockBetweenProvider(blockedCpId));

      print('User unblocked successfully: $blockedCpId');
    } catch (error) {
      print('Error unblocking user: $error');
      rethrow;
    } finally {
      state = false;
    }
  }
}

// ==================== UTILITY PROVIDERS ====================

/// Generate quoted preview from message body
@riverpod
String generateQuotedPreview(Ref ref, String messageBody) {
  const maxLength = 100;

  if (messageBody.length <= maxLength) {
    return messageBody;
  }

  return '${messageBody.substring(0, maxLength)}...';
}
