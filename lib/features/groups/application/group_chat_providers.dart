import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entities/group_message_entity.dart';
import '../data/datasources/group_messages_firestore_datasource.dart';
import '../data/repositories/group_chat_repository.dart';
import '../../community/presentation/providers/community_providers_new.dart';
import 'groups_providers.dart';

part 'group_chat_providers.g.dart';

// ==================== DATA SOURCE PROVIDERS ====================

@riverpod
GroupMessagesDataSource groupMessagesDataSource(Ref ref) {
  return GroupMessagesFirestoreDataSource(FirebaseFirestore.instance);
}

// ==================== REPOSITORY PROVIDERS ====================

@riverpod
GroupChatRepository groupChatRepository(Ref ref) {
  final dataSource = ref.watch(groupMessagesDataSourceProvider);
  final groupsDataSource = ref.watch(groupsDataSourceProvider);
  return GroupChatRepositoryFactory.create(dataSource, groupsDataSource: groupsDataSource);
}

// ==================== MESSAGE STREAM PROVIDERS ====================

/// Provider for watching messages in a specific group with caching and lazy loading
@riverpod
Stream<List<GroupMessageEntity>> groupChatMessages(Ref ref, String groupId) {
  final repository = ref.watch(groupChatRepositoryProvider);

  // Watch the stream and handle errors gracefully
  return repository.watchMessages(groupId).handleError((error) {
    // Log error but don't throw to avoid breaking the UI
    print('Error in groupChatMessages provider for group $groupId: $error');
    return <GroupMessageEntity>[];
  });
}

/// Provider for lazy loading older messages with pagination
@riverpod
class GroupChatMessagesPaginated extends _$GroupChatMessagesPaginated {
  @override
  FutureOr<PaginatedMessagesEntityResult> build(String groupId) async {
    final repository = ref.watch(groupChatRepositoryProvider);

    try {
      // Load initial batch of messages
      return await repository.loadMessages(
        groupId,
        const MessagePaginationEntityParams(
          limit: 20,
          descending: true, // Most recent first for initial load
        ),
      );
    } catch (error) {
      print('Error loading initial messages for group $groupId: $error');
      return const PaginatedMessagesEntityResult(
        messages: [],
        hasMore: false,
      );
    }
  }

  /// Load more older messages
  Future<void> loadMore() async {
    final currentState = state.valueOrNull;
    if (currentState == null || !currentState.hasMore) return;

    final repository = ref.watch(groupChatRepositoryProvider);

    try {
      state = const AsyncValue.loading();

      final moreMessages = await repository.loadMessages(
        groupId,
        MessagePaginationEntityParams(
          limit: 20,
          startAfterId: currentState.lastMessageId,
          descending: true,
        ),
      );

      // Merge with existing messages and remove duplicates
      final existingIds = currentState.messages.map((m) => m.id).toSet();
      final newMessages = moreMessages.messages
          .where((m) => !existingIds.contains(m.id))
          .toList();
      final allMessages = [...currentState.messages, ...newMessages];

      state = AsyncValue.data(
        PaginatedMessagesEntityResult(
          messages: allMessages,
          lastMessageId: moreMessages.lastMessageId,
          hasMore: moreMessages.hasMore,
        ),
      );
    } catch (error) {
      print('Error loading more messages for group $groupId: $error');
      state = AsyncValue.error(error, StackTrace.current);
    }
  }

  /// Refresh messages
  Future<void> refresh() async {
    final repository = ref.watch(groupChatRepositoryProvider);

    try {
      state = const AsyncValue.loading();

      final newMessages = await repository.loadMessages(
        groupId,
        const MessagePaginationEntityParams(
          limit: 20,
          descending: true,
        ),
      );

      state = AsyncValue.data(newMessages);
    } catch (error) {
      print('Error refreshing messages for group $groupId: $error');
      state = AsyncValue.error(error, StackTrace.current);
    }
  }
}

// ==================== MESSAGE SENDING PROVIDERS ====================

/// Service for sending messages (stateless)
@riverpod
class GroupChatService extends _$GroupChatService {
  @override
  bool build() {
    // Simple state to track if operations are in progress
    return false;
  }

  /// Send a message to a group
  Future<void> sendMessage({
    required String groupId,
    required String body,
    String? replyToMessageId,
    String? quotedPreview,
  }) async {
    // Prevent concurrent sends
    if (state) {
      throw Exception('Message send already in progress');
    }

    try {
      state = true; // Mark as busy

      // Get current user's community profile
      final currentProfile =
          await ref.read(currentCommunityProfileProvider.future);
      if (currentProfile == null) {
        throw Exception('Community profile required to send messages');
      }

      final repository = ref.read(groupChatRepositoryProvider);

      // Create message entity
      final message = GroupMessageEntity(
        id: '', // Will be generated by Firestore
        groupId: groupId,
        senderCpId: currentProfile.id,
        body: body.trim(),
        replyToMessageId: replyToMessageId,
        quotedPreview: quotedPreview,
        createdAt: DateTime.now(),
        moderation: const ModerationStatus(
          status: ModerationStatusType
              .approved, // Start as approved - cloud function will change if needed
        ),
      );

      await repository.sendMessage(message);

      // Clear cache to force refresh of message list
      repository.clearCache(groupId);

      print('Message sent successfully to group $groupId');
    } catch (error) {
      print('Error sending message to group $groupId: $error');
      rethrow; // Let UI handle the error
    } finally {
      state = false; // Mark as not busy
    }
  }

  /// Delete a message (soft delete)
  Future<void> deleteMessage(String groupId, String messageId) async {
    if (state) {
      throw Exception('Operation already in progress');
    }

    try {
      state = true;

      final repository = ref.read(groupChatRepositoryProvider);
      await repository.deleteMessage(groupId, messageId);

      // Clear cache to force refresh
      repository.clearCache(groupId);

      print('Message deleted successfully: $messageId');
    } catch (error) {
      print('Error deleting message $messageId: $error');
      rethrow;
    } finally {
      state = false;
    }
  }

  /// Hide a message (moderation action)
  Future<void> hideMessage(String groupId, String messageId) async {
    if (state) {
      throw Exception('Operation already in progress');
    }

    try {
      state = true;

      final repository = ref.read(groupChatRepositoryProvider);
      await repository.hideMessage(groupId, messageId);

      // Clear cache to force refresh
      repository.clearCache(groupId);

      print('Message hidden successfully: $messageId');
    } catch (error) {
      print('Error hiding message $messageId: $error');
      rethrow;
    } finally {
      state = false;
    }
  }

  /// Clear cache for a specific group
  void clearCache(String groupId) {
    final repository = ref.read(groupChatRepositoryProvider);
    repository.clearCache(groupId);
  }

  /// Clear all message cache
  void clearAllCache() {
    final repository = ref.read(groupChatRepositoryProvider);
    repository.clearAllCache();
  }
}

// ==================== UTILITY PROVIDERS ====================

/// Provider to check if user can access chat for a group
@riverpod
Future<bool> canAccessGroupChat(Ref ref, String groupId) async {
  try {
    // Check if user has community profile
    final currentProfile =
        await ref.watch(currentCommunityProfileProvider.future);
    if (currentProfile == null) return false;

    // TODO: Add membership check here
    // For now, assume access if profile exists
    // In production, should check group_memberships collection
    return true;
  } catch (error) {
    print('Error checking group chat access for $groupId: $error');
    return false;
  }
}

/// Provider to check if current user is admin of a specific group
@riverpod
Future<bool> isCurrentUserGroupAdmin(Ref ref, String groupId) async {
  try {
    // Get current community profile
    final currentProfile =
        await ref.watch(currentCommunityProfileProvider.future);
    if (currentProfile == null) return false;

    // Query group_memberships collection to check user's role
    final firestore = FirebaseFirestore.instance;
    final membershipDoc = await firestore
        .collection('group_memberships')
        .where('groupId', isEqualTo: groupId)
        .where('cpId', isEqualTo: currentProfile.id)
        .where('isActive', isEqualTo: true)
        .limit(1)
        .get();

    if (membershipDoc.docs.isEmpty) return false;

    // Check if user has admin role
    final membershipData = membershipDoc.docs.first.data();
    final role = membershipData['role'] as String?;

    return role == 'admin';
  } catch (e) {
    print('Error checking admin status for group $groupId: $e');
    return false;
  }
}

/// Provider for generating quoted preview from reply target
@riverpod
String generateQuotedPreview(Ref ref, String messageBody) {
  const maxLength = 100; // Match schema recommendation

  if (messageBody.length <= maxLength) {
    return messageBody;
  }

  return '${messageBody.substring(0, maxLength)}...';
}

// ==================== PINNED MESSAGES PROVIDERS ====================

/// Provider for watching pinned messages in a specific group
@riverpod
Future<List<GroupMessageEntity>> pinnedMessages(Ref ref, String groupId) async {
  final repository = ref.watch(groupChatRepositoryProvider);
  
  try {
    return await repository.getPinnedMessages(groupId);
  } catch (error) {
    print('Error fetching pinned messages for group $groupId: $error');
    return [];
  }
}

/// Service for managing pinned messages
@riverpod
class PinnedMessagesService extends _$PinnedMessagesService {
  @override
  bool build() {
    // Simple state to track if operations are in progress
    return false;
  }

  /// Pin a message (admin only)
  Future<void> pinMessage({
    required String groupId,
    required String messageId,
  }) async {
    if (state) {
      throw Exception('Operation already in progress');
    }

    try {
      state = true;

      // Get current user's community profile
      final currentProfile =
          await ref.read(currentCommunityProfileProvider.future);
      if (currentProfile == null) {
        throw Exception('Community profile required to pin messages');
      }

      // Verify user is admin
      final isAdmin = await ref.read(isCurrentUserGroupAdminProvider(groupId).future);
      if (!isAdmin) {
        throw Exception('Only admins can pin messages');
      }

      final repository = ref.read(groupChatRepositoryProvider);
      await repository.pinMessage(
        groupId: groupId,
        messageId: messageId,
        adminCpId: currentProfile.id,
      );

      // Invalidate pinned messages cache
      ref.invalidate(pinnedMessagesProvider(groupId));

      print('Message pinned successfully: $messageId');
    } catch (error) {
      print('Error pinning message $messageId: $error');
      rethrow;
    } finally {
      state = false;
    }
  }

  /// Unpin a message (admin only)
  Future<void> unpinMessage({
    required String groupId,
    required String messageId,
  }) async {
    if (state) {
      throw Exception('Operation already in progress');
    }

    try {
      state = true;

      // Verify user is admin
      final isAdmin = await ref.read(isCurrentUserGroupAdminProvider(groupId).future);
      if (!isAdmin) {
        throw Exception('Only admins can unpin messages');
      }

      final repository = ref.read(groupChatRepositoryProvider);
      await repository.unpinMessage(
        groupId: groupId,
        messageId: messageId,
      );

      // Invalidate pinned messages cache
      ref.invalidate(pinnedMessagesProvider(groupId));

      print('Message unpinned successfully: $messageId');
    } catch (error) {
      print('Error unpinning message $messageId: $error');
      rethrow;
    } finally {
      state = false;
    }
  }
}

// ==================== CACHE MANAGEMENT ====================

/// Provider for managing message cache
@riverpod
class MessageCacheManager extends _$MessageCacheManager {
  @override
  Map<String, DateTime> build() {
    return {};
  }

  /// Mark cache as dirty for a group
  void markCacheDirty(String groupId) {
    state = {...state, groupId: DateTime.now()};
  }

  /// Check if cache is dirty for a group
  bool isCacheDirty(String groupId, Duration threshold) {
    final lastUpdate = state[groupId];
    if (lastUpdate == null) return true;

    return DateTime.now().difference(lastUpdate) > threshold;
  }

  /// Clear cache tracking for a group
  void clearCacheTracking(String groupId) {
    final newState = Map<String, DateTime>.from(state);
    newState.remove(groupId);
    state = newState;
  }
}
