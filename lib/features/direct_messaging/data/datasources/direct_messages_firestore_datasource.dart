import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/direct_message_model.dart';

/// Pagination parameters for loading messages
class MessagePaginationParams {
  final int limit;
  final DocumentSnapshot? startAfter;

  const MessagePaginationParams({
    this.limit = 50,
    this.startAfter,
  });
}

/// Result of paginated message load
class PaginatedMessagesResult {
  final List<DirectMessageModel> messages;
  final DocumentSnapshot? lastDocument;
  final bool hasMore;

  const PaginatedMessagesResult({
    required this.messages,
    this.lastDocument,
    required this.hasMore,
  });
}

/// Abstract interface for direct messages data source
abstract class DirectMessagesDataSource {
  Stream<List<DirectMessageModel>> watchMessages(String conversationId);
  Future<PaginatedMessagesResult> loadMessages(
    String conversationId,
    MessagePaginationParams params,
  );
  Future<void> sendMessage(DirectMessageModel message);
  Future<void> deleteMessage(String conversationId, String messageId);
  Future<void> hideMessage(String conversationId, String messageId);
  void clearCache(String conversationId);
}

/// Firestore implementation of DirectMessagesDataSource
class DirectMessagesFirestoreDataSource implements DirectMessagesDataSource {
  final FirebaseFirestore _firestore;
  
  // Caching
  final Map<String, List<DirectMessageModel>> _messageCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  final Map<String, Stream<List<DirectMessageModel>>> _streamCache = {};
  final Map<String, DocumentSnapshot> _documentCache = {};
  static const _cacheDuration = Duration(minutes: 5);

  DirectMessagesFirestoreDataSource(this._firestore);

  CollectionReference<Map<String, dynamic>> get _messagesCollection =>
      _firestore.collection('direct_messages');

  @override
  Stream<List<DirectMessageModel>> watchMessages(String conversationId) {
    // Return cached stream if available
    if (_streamCache.containsKey(conversationId)) {
      return _streamCache[conversationId]!;
    }

    // Create new stream with caching
    final stream = _messagesCollection
        .where('conversationId', isEqualTo: conversationId)
        .orderBy('createdAt', descending: false) // Ascending for chat UI
        .snapshots()
        .asyncMap((snapshot) async {
      try {
        // Don't filter by visibility here - let the UI layer handle it with current user context
        final messages = snapshot.docs
            .map((doc) => DirectMessageModel.fromFirestore(doc))
            .where((msg) => !msg.isDeleted) // Only filter deleted messages
            .toList();

        // Cache document snapshots for pagination
        for (final doc in snapshot.docs) {
          _documentCache[doc.id] = doc;
        }

        // Update cache with latest messages
        _updateCacheWithLatestMessages(conversationId, messages);

        return messages;
      } catch (e, stackTrace) {
        log('Error processing message stream: $e', stackTrace: stackTrace);
        return <DirectMessageModel>[];
      }
    }).handleError((error) {
      log('Error in message stream for conversation $conversationId: $error');
      return <DirectMessageModel>[];
    });

    // Cache the stream
    _streamCache[conversationId] = stream;

    return stream;
  }

  @override
  Future<PaginatedMessagesResult> loadMessages(
    String conversationId,
    MessagePaginationParams params,
  ) async {
    try {
      log('Loading messages for conversation $conversationId with limit ${params.limit}');

      // Check cache first (only for initial load)
      if (params.startAfter == null && _isCacheValid(conversationId)) {
        final cachedMessages = _messageCache[conversationId]!;
        log('Returning ${cachedMessages.length} cached messages');
        return PaginatedMessagesResult(
          messages: cachedMessages,
          lastDocument: cachedMessages.isNotEmpty
              ? _documentCache[cachedMessages.last.id]
              : null,
          hasMore: cachedMessages.length >= params.limit,
        );
      }

      // Build query
      Query<Map<String, dynamic>> query = _messagesCollection
          .where('conversationId', isEqualTo: conversationId)
          .orderBy('createdAt', descending: true) // Descending for pagination
          .limit(params.limit + 1); // +1 to check if more exist

      // Add pagination cursor if provided
      if (params.startAfter != null) {
        query = query.startAfterDocument(params.startAfter!);
      }

      final querySnapshot = await query.get();
      final messageDocs = querySnapshot.docs;

      // Check if more messages exist
      final hasMore = messageDocs.length > params.limit;
      final messages = messageDocs
          .take(params.limit)
          .map((doc) => DirectMessageModel.fromFirestore(doc))
          .where((msg) => !msg.isDeleted) // Only filter deleted, not visibility (handled in UI)
          .toList();

      // Cache document references
      for (final doc in messageDocs) {
        _documentCache[doc.id] = doc;
      }

      final lastDocument = messageDocs.isNotEmpty ? messageDocs.last : null;

      final result = PaginatedMessagesResult(
        messages: messages,
        lastDocument: lastDocument,
        hasMore: hasMore,
      );

      // Cache the result if it's the initial load
      if (params.startAfter == null) {
        _cacheMessages(conversationId, result);
      }

      log('Loaded ${messages.length} messages, hasMore: $hasMore');
      return result;
    } catch (e, stackTrace) {
      log('Error loading messages: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> sendMessage(DirectMessageModel message) async {
    try {
      log('Sending message to conversation ${message.conversationId}');

      await _messagesCollection.add(message.toFirestore());

      // Invalidate cache to force refresh
      _messageCache.remove(message.conversationId);

      log('Message sent successfully');
    } catch (e, stackTrace) {
      log('Error sending message: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> deleteMessage(String conversationId, String messageId) async {
    try {
      log('Deleting message $messageId in conversation $conversationId');

      await _messagesCollection.doc(messageId).update({
        'isDeleted': true,
      });

      // Invalidate cache
      _messageCache.remove(conversationId);

      log('Message deleted successfully');
    } catch (e, stackTrace) {
      log('Error deleting message: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> hideMessage(String conversationId, String messageId) async {
    try {
      log('Hiding message $messageId in conversation $conversationId');

      await _messagesCollection.doc(messageId).update({
        'isHidden': true,
      });

      // Invalidate cache
      _messageCache.remove(conversationId);

      log('Message hidden successfully');
    } catch (e, stackTrace) {
      log('Error hiding message: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  void clearCache(String conversationId) {
    _messageCache.remove(conversationId);
    _cacheTimestamps.remove(conversationId);
    _streamCache.remove(conversationId);
  }

  // Cache helpers
  bool _isCacheValid(String conversationId) {
    if (!_messageCache.containsKey(conversationId)) return false;
    final timestamp = _cacheTimestamps[conversationId];
    if (timestamp == null) return false;
    return DateTime.now().difference(timestamp) < _cacheDuration;
  }

  void _cacheMessages(String conversationId, PaginatedMessagesResult result) {
    _messageCache[conversationId] = result.messages;
    _cacheTimestamps[conversationId] = DateTime.now();
  }

  void _updateCacheWithLatestMessages(
    String conversationId,
    List<DirectMessageModel> messages,
  ) {
    _messageCache[conversationId] = messages;
    _cacheTimestamps[conversationId] = DateTime.now();
  }
}


