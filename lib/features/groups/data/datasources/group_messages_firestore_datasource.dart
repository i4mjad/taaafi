import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/group_message_model.dart';

/// Pagination parameters for message loading
class MessagePaginationParams {
  final int limit;
  final DocumentSnapshot? startAfter;
  final bool descending;

  const MessagePaginationParams({
    this.limit = 20,
    this.startAfter,
    this.descending = true,
  });

  MessagePaginationParams copyWith({
    int? limit,
    DocumentSnapshot? startAfter,
    bool? descending,
  }) {
    return MessagePaginationParams(
      limit: limit ?? this.limit,
      startAfter: startAfter ?? this.startAfter,
      descending: descending ?? this.descending,
    );
  }
}

/// Result of paginated message query
class PaginatedMessagesResult {
  final List<GroupMessageModel> messages;
  final DocumentSnapshot? lastDocument;
  final bool hasMore;

  const PaginatedMessagesResult({
    required this.messages,
    this.lastDocument,
    required this.hasMore,
  });
}

/// Cache entry for group messages
class MessageCacheEntry {
  final List<GroupMessageModel> messages;
  final DateTime timestamp;
  final DocumentSnapshot? lastDocument;
  final bool hasMore;

  const MessageCacheEntry({
    required this.messages,
    required this.timestamp,
    this.lastDocument,
    required this.hasMore,
  });

  bool get isExpired {
    return DateTime.now().difference(timestamp).inMinutes > 5;
  }
}

/// Cache entry for community profiles
class CommunityProfileCacheEntry {
  final String displayName;
  final bool isAnonymous;
  final String? avatarUrl;
  final DateTime timestamp;
  final DateTime? profileUpdatedAt;

  const CommunityProfileCacheEntry({
    required this.displayName,
    required this.isAnonymous,
    this.avatarUrl,
    required this.timestamp,
    this.profileUpdatedAt,
  });

  bool get isExpired {
    // Cache for 10 minutes, or if profile was updated after cache
    final now = DateTime.now();
    final cacheAge = now.difference(timestamp).inMinutes > 10;
    final profileNewer =
        profileUpdatedAt != null && profileUpdatedAt!.isAfter(timestamp);

    return cacheAge || profileNewer;
  }
}

/// Abstract interface for group messages data source
abstract class GroupMessagesDataSource {
  /// Watch messages for a group with real-time updates
  Stream<List<GroupMessageModel>> watchMessages(String groupId);

  /// Load messages with pagination
  Future<PaginatedMessagesResult> loadMessages(
    String groupId,
    MessagePaginationParams params,
  );

  /// Send a new message
  Future<void> sendMessage(GroupMessageModel message);

  /// Delete a message (soft delete)
  Future<void> deleteMessage(String groupId, String messageId);

  /// Hide a message (moderation)
  Future<void> hideMessage(String groupId, String messageId);

  /// Unhide a message (moderation)
  Future<void> unhideMessage(String groupId, String messageId);

  /// Pin a message (admin only, max 3 pinned)
  Future<void> pinMessage({
    required String groupId,
    required String messageId,
    required String adminCpId,
  });

  /// Unpin a message
  Future<void> unpinMessage({
    required String groupId,
    required String messageId,
  });

  /// Get pinned messages for a group
  Future<List<GroupMessageModel>> getPinnedMessages(String groupId);

  /// Toggle reaction on a message (add if not present, remove if present)
  Future<void> toggleReaction({
    required String groupId,
    required String messageId,
    required String cpId,
    required String emoji,
  });

  /// Search messages by keyword in a group
  Future<List<GroupMessageModel>> searchMessages({
    required String groupId,
    required String query,
    int limit = 50,
  });

  /// Clear cache for a specific group
  void clearCache(String groupId);

  /// Clear all cache
  void clearAllCache();

  /// Get DocumentSnapshot by message ID for pagination
  DocumentSnapshot? getDocumentSnapshot(String messageId);
}

/// Enhanced message with sender profile info
class EnhancedGroupMessage {
  final GroupMessageModel message;
  final String senderDisplayName;
  final bool senderIsAnonymous;
  final String? senderAvatarUrl;
  final Color senderAvatarColor;

  const EnhancedGroupMessage({
    required this.message,
    required this.senderDisplayName,
    required this.senderIsAnonymous,
    this.senderAvatarUrl,
    required this.senderAvatarColor,
  });
}

/// Firestore implementation with caching and pagination
class GroupMessagesFirestoreDataSource implements GroupMessagesDataSource {
  final FirebaseFirestore _firestore;

  // In-memory cache for messages
  final Map<String, MessageCacheEntry> _messageCache = {};

  // Cache for real-time streams to avoid duplicate subscriptions
  final Map<String, Stream<List<GroupMessageModel>>> _streamCache = {};

  // Cache for community profiles (with timestamp for invalidation)
  final Map<String, CommunityProfileCacheEntry> _profileCache = {};

  // Cache for DocumentSnapshots by message ID for pagination
  final Map<String, DocumentSnapshot> _documentCache = {};

  GroupMessagesFirestoreDataSource(this._firestore);

  CollectionReference get _messagesCollection =>
      _firestore.collection('group_messages');

  @override
  Stream<List<GroupMessageModel>> watchMessages(String groupId) {
    // Return cached stream if available
    if (_streamCache.containsKey(groupId)) {
      return _streamCache[groupId]!;
    }

    // Create new stream with caching and profile enrichment
    final stream = _messagesCollection
        .where('groupId', isEqualTo: groupId)
        .orderBy('createdAt', descending: false) // Ascending for chat UI
        // Remove limit to get all messages in real-time stream
        .snapshots()
        .asyncMap((snapshot) async {
      try {
        final messages = snapshot.docs
            .map((doc) => GroupMessageModel.fromFirestore(doc))
            .where((msg) => !msg
                .isDeleted) // Only filter out deleted messages, keep hidden ones
            .toList();

        // Cache document snapshots for pagination
        for (final doc in snapshot.docs) {
          _documentCache[doc.id] = doc;
        }

        // Batch fetch profiles for all unique senders
        await _batchFetchProfiles(
            messages.map((m) => m.senderCpId).toSet().toList());

        // Update cache with latest messages
        _updateCacheWithLatestMessages(groupId, messages);

        return messages;
      } catch (e, stackTrace) {
        log('Error processing message stream: $e', stackTrace: stackTrace);
        return <GroupMessageModel>[];
      }
    }).handleError((error) {
      log('Error in message stream for group $groupId: $error');
      return <GroupMessageModel>[];
    });

    // Cache the stream
    _streamCache[groupId] = stream;

    return stream;
  }

  @override
  Future<PaginatedMessagesResult> loadMessages(
    String groupId,
    MessagePaginationParams params,
  ) async {
    try {
      // Check cache first for initial load
      if (params.startAfter == null) {
        final cachedEntry = _messageCache[groupId];
        if (cachedEntry != null && !cachedEntry.isExpired) {
          log('Returning cached messages for group $groupId');
          return PaginatedMessagesResult(
            messages: cachedEntry.messages,
            lastDocument: cachedEntry.lastDocument,
            hasMore: cachedEntry.hasMore,
          );
        }
      }

      log('Loading messages from Firestore for group $groupId, limit: ${params.limit}');

      // Build query
      Query query = _messagesCollection
          .where('groupId', isEqualTo: groupId)
          .orderBy('createdAt', descending: params.descending)
          .limit(params.limit + 1); // +1 to check if there are more

      // Add pagination if provided
      if (params.startAfter != null) {
        query = query.startAfterDocument(params.startAfter!);
      }

      final querySnapshot = await query.get();

      if (querySnapshot.docs.isEmpty) {
        log('No messages found for group $groupId');
        return const PaginatedMessagesResult(
          messages: [],
          hasMore: false,
        );
      }

      // Process messages
      final allDocs = querySnapshot.docs;
      final hasMore = allDocs.length > params.limit;
      final messageDocs =
          hasMore ? allDocs.take(params.limit).toList() : allDocs;

      final messages = messageDocs
          .map((doc) => GroupMessageModel.fromFirestore(doc))
          .where((msg) => !msg
              .isDeleted) // Only filter out deleted messages, keep hidden ones
          .toList();

      // Cache document snapshots for pagination
      for (final doc in messageDocs) {
        _documentCache[doc.id] = doc;
      }

      // Batch fetch profiles for all unique senders
      await _batchFetchProfiles(
          messages.map((m) => m.senderCpId).toSet().toList());

      final lastDocument = messageDocs.isNotEmpty ? messageDocs.last : null;

      final result = PaginatedMessagesResult(
        messages: messages,
        lastDocument: lastDocument,
        hasMore: hasMore,
      );

      // Cache the result if it's the initial load
      if (params.startAfter == null) {
        _cacheMessages(groupId, result);
      }

      log('Loaded ${messages.length} messages for group $groupId, hasMore: $hasMore');
      return result;
    } catch (e, stackTrace) {
      log('Error loading messages for group $groupId: $e',
          stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> sendMessage(GroupMessageModel message) async {
    try {
      log('Sending message to group ${message.groupId}');

      await _messagesCollection.add(message.toFirestore());

      // Invalidate cache to force refresh
      _messageCache.remove(message.groupId);
      // Note: We don't clear _documentCache as it should be updated by the real-time stream

      log('Message sent successfully to group ${message.groupId}');
    } catch (e, stackTrace) {
      log('Error sending message: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> deleteMessage(String groupId, String messageId) async {
    try {
      log('Deleting message $messageId in group $groupId');

      await _messagesCollection.doc(messageId).update({
        'isDeleted': true,
      });

      // Invalidate cache
      _messageCache.remove(groupId);

      log('Message deleted successfully');
    } catch (e, stackTrace) {
      log('Error deleting message: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> hideMessage(String groupId, String messageId) async {
    try {
      log('Hiding message $messageId in group $groupId');

      await _messagesCollection.doc(messageId).update({
        'isHidden': true,
      });

      // Invalidate cache to ensure real-time updates
      _messageCache.remove(groupId);
      _streamCache.remove(groupId);

      log('Message hidden successfully');
    } catch (e, stackTrace) {
      log('Error hiding message: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> unhideMessage(String groupId, String messageId) async {
    try {
      log('Unhiding message $messageId in group $groupId');

      await _messagesCollection.doc(messageId).update({
        'isHidden': false,
      });

      // Invalidate cache to ensure real-time updates
      _messageCache.remove(groupId);
      _streamCache.remove(groupId);

      log('Message unhidden successfully');
    } catch (e, stackTrace) {
      log('Error unhiding message: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> pinMessage({
    required String groupId,
    required String messageId,
    required String adminCpId,
  }) async {
    try {
      log('Pinning message $messageId in group $groupId by admin $adminCpId');

      // Check if max 3 pinned messages limit
      final pinnedMessages = await getPinnedMessages(groupId);
      if (pinnedMessages.length >= 3) {
        throw Exception('Maximum 3 messages can be pinned per group');
      }

      // Check if message exists and is not deleted/hidden/blocked
      final messageDoc = await _messagesCollection.doc(messageId).get();
      if (!messageDoc.exists) {
        throw Exception('Message not found');
      }

      final messageData = messageDoc.data() as Map<String, dynamic>;
      if (messageData['isDeleted'] == true || messageData['isHidden'] == true) {
        throw Exception('Cannot pin deleted or hidden messages');
      }

      // Check if message is blocked
      final moderation = messageData['moderation'] as Map<String, dynamic>?;
      if (moderation != null && moderation['status'] == 'blocked') {
        throw Exception('Cannot pin blocked messages');
      }

      // Pin the message
      await _messagesCollection.doc(messageId).update({
        'isPinned': true,
        'pinnedAt': FieldValue.serverTimestamp(),
        'pinnedBy': adminCpId,
      });

      // Invalidate cache
      _messageCache.remove(groupId);
      _streamCache.remove(groupId);

      log('Message pinned successfully');
    } catch (e, stackTrace) {
      log('Error pinning message: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> unpinMessage({
    required String groupId,
    required String messageId,
  }) async {
    try {
      log('Unpinning message $messageId in group $groupId');

      await _messagesCollection.doc(messageId).update({
        'isPinned': false,
        'pinnedAt': FieldValue.delete(),
        'pinnedBy': FieldValue.delete(),
      });

      // Invalidate cache
      _messageCache.remove(groupId);
      _streamCache.remove(groupId);

      log('Message unpinned successfully');
    } catch (e, stackTrace) {
      log('Error unpinning message: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<List<GroupMessageModel>> getPinnedMessages(String groupId) async {
    try {
      log('Fetching pinned messages for group $groupId');

      final snapshot = await _messagesCollection
          .where('groupId', isEqualTo: groupId)
          .where('isPinned', isEqualTo: true)
          .orderBy('pinnedAt', descending: false)
          .limit(3)
          .get();

      final pinnedMessages = snapshot.docs
          .map((doc) => GroupMessageModel.fromFirestore(doc))
          .toList();

      log('Found ${pinnedMessages.length} pinned messages');
      return pinnedMessages;
    } catch (e, stackTrace) {
      log('Error fetching pinned messages: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> toggleReaction({
    required String groupId,
    required String messageId,
    required String cpId,
    required String emoji,
  }) async {
    try {
      log('Toggling reaction $emoji on message $messageId by $cpId');

      // Get current message to check reactions
      final messageDoc = await _messagesCollection.doc(messageId).get();
      if (!messageDoc.exists) {
        throw Exception('Message not found');
      }

      final messageData = messageDoc.data() as Map<String, dynamic>;
      final currentReactions = _parseReactions(messageData['reactions']);

      // Toggle logic: if user already reacted with this emoji, remove it; otherwise add it
      final List<String> emojiReactions = List<String>.from(currentReactions[emoji] ?? []);
      
      if (emojiReactions.contains(cpId)) {
        // Remove reaction
        emojiReactions.remove(cpId);
        log('Removing reaction $emoji from user $cpId');
      } else {
        // Add reaction
        emojiReactions.add(cpId);
        log('Adding reaction $emoji from user $cpId');
      }

      // Update reactions map
      final updatedReactions = Map<String, List<String>>.from(currentReactions);
      if (emojiReactions.isEmpty) {
        // Remove emoji key if no reactions left
        updatedReactions.remove(emoji);
      } else {
        updatedReactions[emoji] = emojiReactions;
      }

      // Update message document
      await _messagesCollection.doc(messageId).update({
        'reactions': updatedReactions,
      });

      // Invalidate cache
      _messageCache.remove(groupId);
      _streamCache.remove(groupId);

      log('Reaction toggled successfully');
    } catch (e, stackTrace) {
      log('Error toggling reaction: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<List<GroupMessageModel>> searchMessages({
    required String groupId,
    required String query,
    int limit = 50,
  }) async {
    try {
      log('Searching messages in group $groupId with query: $query');

      if (query.trim().isEmpty) {
        return [];
      }

      // Normalize query for case-insensitive search
      final normalizedQuery = query.trim().toLowerCase();

      // Fetch all non-deleted messages from the group
      // Note: For large groups, this could be optimized by using pagination or indexed search
      final snapshot = await _messagesCollection
          .where('groupId', isEqualTo: groupId)
          .where('isDeleted', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .limit(500) // Limit to last 500 messages for performance
          .get();

      // Client-side filtering using case-insensitive search
      final matchingMessages = <GroupMessageModel>[];
      
      for (final doc in snapshot.docs) {
        final message = GroupMessageModel.fromFirestore(doc);
        
        // Skip hidden messages
        if (message.isHidden) {
          continue;
        }
        
        // Skip blocked messages (from moderation)
        final moderationData = doc.data() as Map<String, dynamic>;
        final moderation = moderationData['moderation'] as Map<String, dynamic>?;
        final moderationStatus = moderation?['status'] as String?;
        if (moderationStatus == 'blocked') {
          continue;
        }
        
        // Search in message body (case-insensitive)
        if (message.body.toLowerCase().contains(normalizedQuery)) {
          matchingMessages.add(message);
          
          if (matchingMessages.length >= limit) {
            break;
          }
        }
      }

      log('Found ${matchingMessages.length} matching messages');
      return matchingMessages;
    } catch (e, stackTrace) {
      log('Error searching messages: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Parse reactions from Firestore format
  Map<String, List<String>> _parseReactions(dynamic reactionsData) {
    if (reactionsData == null) return {};
    
    final Map<String, dynamic> rawReactions = Map<String, dynamic>.from(reactionsData);
    final Map<String, List<String>> reactions = {};
    
    for (final entry in rawReactions.entries) {
      reactions[entry.key] = List<String>.from(entry.value ?? []);
    }
    
    return reactions;
  }

  @override
  void clearCache(String groupId) {
    _messageCache.remove(groupId);
    _streamCache.remove(groupId);
    // Note: We don't clear _documentCache or _profileCache by groupId
    // as they are global caches
    log('Cache cleared for group $groupId');
  }

  @override
  void clearAllCache() {
    _messageCache.clear();
    _streamCache.clear();
    _documentCache.clear();
    _profileCache.clear();
    log('All caches cleared');
  }

  /// Get DocumentSnapshot by message ID for pagination
  DocumentSnapshot? getDocumentSnapshot(String messageId) {
    return _documentCache[messageId];
  }

  /// Helper method to cache messages
  void _cacheMessages(String groupId, PaginatedMessagesResult result) {
    _messageCache[groupId] = MessageCacheEntry(
      messages: result.messages,
      timestamp: DateTime.now(),
      lastDocument: result.lastDocument,
      hasMore: result.hasMore,
    );
    log('Cached ${result.messages.length} messages for group $groupId');
  }

  /// Helper method to update cache with latest real-time messages
  void _updateCacheWithLatestMessages(
      String groupId, List<GroupMessageModel> latestMessages) {
    final existingEntry = _messageCache[groupId];
    if (existingEntry != null) {
      // Merge with existing cached messages, avoiding duplicates
      final existingIds = existingEntry.messages.map((m) => m.id).toSet();
      final newMessages =
          latestMessages.where((m) => !existingIds.contains(m.id)).toList();

      if (newMessages.isNotEmpty) {
        final updatedMessages = [...existingEntry.messages, ...newMessages];
        // Keep messages sorted by creation time (ascending order)
        updatedMessages.sort((a, b) => a.createdAt.compareTo(b.createdAt));

        _messageCache[groupId] = MessageCacheEntry(
          messages: updatedMessages,
          timestamp: DateTime.now(),
          lastDocument: existingEntry.lastDocument,
          hasMore: existingEntry.hasMore,
        );
        log('Updated cache with ${newMessages.length} new messages for group $groupId');
      }
    } else {
      // If no existing cache, create a new cache entry
      if (latestMessages.isNotEmpty) {
        _messageCache[groupId] = MessageCacheEntry(
          messages: latestMessages,
          timestamp: DateTime.now(),
          lastDocument: null, // Will be set by pagination
          hasMore: true, // Assume there might be more until proven otherwise
        );
        log('Created new cache with ${latestMessages.length} messages for group $groupId');
      }
    }
  }

  /// Batch fetch community profiles for multiple cpIds
  Future<void> _batchFetchProfiles(List<String> cpIds) async {
    if (cpIds.isEmpty) return;

    final now = DateTime.now();
    final missingCpIds = cpIds.where((cpId) {
      final cached = _profileCache[cpId];
      return cached == null || cached.isExpired;
    }).toList();

    if (missingCpIds.isEmpty) {
      log('All ${cpIds.length} profiles found in cache');
      return;
    }

    log('Fetching ${missingCpIds.length} missing profiles from ${cpIds.length} total');

    try {
      // Firestore 'in' query supports up to 10 items, so batch them
      const batchSize = 10;
      final batches = <List<String>>[];
      for (int i = 0; i < missingCpIds.length; i += batchSize) {
        final end = (i + batchSize < missingCpIds.length)
            ? i + batchSize
            : missingCpIds.length;
        batches.add(missingCpIds.sublist(i, end));
      }

      // Fetch all batches in parallel
      final futures = batches.map((batch) async {
        final querySnapshot = await _firestore
            .collection('communityProfiles')
            .where(FieldPath.documentId, whereIn: batch)
            .get();

        for (final doc in querySnapshot.docs) {
          if (!doc.exists) continue;

          final data = doc.data();
          final updatedAt = data['updatedAt'] != null
              ? (data['updatedAt'] as Timestamp).toDate()
              : null;

          _profileCache[doc.id] = CommunityProfileCacheEntry(
            displayName: data['displayName'] ?? 'مستخدم',
            isAnonymous: data['isAnonymous'] ?? false,
            avatarUrl: data['avatarUrl'],
            timestamp: now,
            profileUpdatedAt: updatedAt,
          );
        }
      });

      await Future.wait(futures);

      // Add fallback entries for profiles that don't exist
      for (final cpId in missingCpIds) {
        if (!_profileCache.containsKey(cpId)) {
          _profileCache[cpId] = CommunityProfileCacheEntry(
            displayName: 'مستخدم سابق',
            isAnonymous: true,
            timestamp: now,
          );
        }
      }

      log('Successfully cached ${missingCpIds.length} profiles');
    } catch (e, stackTrace) {
      log('Error batch fetching profiles: $e', stackTrace: stackTrace);

      // Add fallback entries for failed fetches
      for (final cpId in missingCpIds) {
        if (!_profileCache.containsKey(cpId)) {
          _profileCache[cpId] = CommunityProfileCacheEntry(
            displayName: 'مجهول',
            isAnonymous: true,
            timestamp: now,
          );
        }
      }
    }
  }

  /// Get sender display name respecting anonymity
  String getSenderDisplayName(String cpId) {
    final cached = _profileCache[cpId];
    if (cached == null) {
      return 'مجهول'; // Fallback
    }

    if (cached.isAnonymous) {
      return 'مجهول';
    } else {
      return cached.displayName.isEmpty ? 'مستخدم' : cached.displayName;
    }
  }

  /// Get sender avatar color (consistent per user)
  /// Anonymous users get different vibrant colors based on their profile ID
  Color getSenderAvatarColor(String cpId) {
    final cached = _profileCache[cpId];
    final isAnonymous = cached?.isAnonymous ?? true;

    if (isAnonymous) {
      // More diverse colors for anonymous users
      final anonymousColors = [
        const Color(0xFF6B73FF), // Vibrant Blue
        const Color(0xFF9333EA), // Purple
        const Color(0xFFEC4899), // Pink
        const Color(0xFFEF4444), // Red
        const Color(0xFFF59E0B), // Amber
        const Color(0xFF10B981), // Emerald
        const Color(0xFF06B6D4), // Cyan
        const Color(0xFF8B5CF6), // Violet
        const Color(0xFFF97316), // Orange
        const Color(0xFF84CC16), // Lime
        const Color(0xFF14B8A6), // Teal
        const Color(0xFFE11D48), // Rose
        const Color(0xFF7C3AED), // Indigo
        const Color(0xFF059669), // Green
        const Color(0xFFDB2777), // Hot Pink
        const Color(0xFF0EA5E9), // Sky Blue
      ];

      final index = cpId.hashCode.abs() % anonymousColors.length;
      return anonymousColors[index];
    } else {
      // Regular colors for non-anonymous users
      final regularColors = [
        Colors.blue,
        Colors.green,
        Colors.orange,
        Colors.purple,
        Colors.teal,
        Colors.pink,
        Colors.indigo,
        Colors.cyan,
      ];

      final index = cpId.hashCode.abs() % regularColors.length;
      return regularColors[index];
    }
  }

  /// Get sender anonymity status
  bool getSenderAnonymity(String cpId) {
    final cached = _profileCache[cpId];
    return cached?.isAnonymous ?? true;
  }

  /// Get sender avatar URL (for non-anonymous users)
  String? getSenderAvatarUrl(String cpId) {
    final cached = _profileCache[cpId];
    if (cached == null || cached.isAnonymous) {
      return null; // Anonymous users don't show real avatars
    }
    return cached.avatarUrl;
  }

  /// Clear profile cache for a specific cpId (when profile is updated)
  void clearProfileCache(String cpId) {
    _profileCache.remove(cpId);
    log('Profile cache cleared for cpId: $cpId');
  }
}

/// Extension to add visibility check to GroupMessageModel
extension GroupMessageModelExtensions on GroupMessageModel {
  bool get isVisible {
    if (isDeleted || isHidden) return false;

    final moderationStatus = moderation['status'] as String?;
    return moderationStatus != 'blocked';
  }
}
