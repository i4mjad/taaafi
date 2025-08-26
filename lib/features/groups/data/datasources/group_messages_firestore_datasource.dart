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

  /// Clear cache for a specific group
  void clearCache(String groupId);

  /// Clear all cache
  void clearAllCache();
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
        .limit(50) // Limit real-time messages to recent ones
        .snapshots()
        .asyncMap((snapshot) async {
      try {
        final messages = snapshot.docs
            .map((doc) => GroupMessageModel.fromFirestore(doc))
            .where((msg) => msg.isVisible) // Filter out deleted/hidden messages
            .toList();

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
          .where((msg) => msg.isVisible) // Filter out deleted/hidden messages
          .toList();

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

      // Invalidate cache
      _messageCache.remove(groupId);

      log('Message hidden successfully');
    } catch (e, stackTrace) {
      log('Error hiding message: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  void clearCache(String groupId) {
    _messageCache.remove(groupId);
    _streamCache.remove(groupId);
    log('Cache cleared for group $groupId');
  }

  @override
  void clearAllCache() {
    _messageCache.clear();
    _streamCache.clear();
    log('All message cache cleared');
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
        // Keep messages sorted by creation time
        updatedMessages.sort((a, b) => a.createdAt.compareTo(b.createdAt));

        _messageCache[groupId] = MessageCacheEntry(
          messages: updatedMessages,
          timestamp: DateTime.now(),
          lastDocument: existingEntry.lastDocument,
          hasMore: existingEntry.hasMore,
        );
        log('Updated cache with ${newMessages.length} new messages for group $groupId');
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
            displayName: 'عضو مجهول',
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
      return 'عضو مجهول'; // Fallback
    }

    if (cached.isAnonymous) {
      return 'عضو مجهول';
    } else {
      return cached.displayName.isEmpty ? 'مستخدم' : cached.displayName;
    }
  }

  /// Get sender avatar color (consistent per user)
  Color getSenderAvatarColor(String cpId) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.cyan,
    ];

    final index = cpId.hashCode.abs() % colors.length;
    return colors[index];
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
