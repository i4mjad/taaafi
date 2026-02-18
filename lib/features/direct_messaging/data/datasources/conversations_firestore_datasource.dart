import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/direct_conversation_model.dart';

/// Abstract interface for conversations data source
abstract class ConversationsDataSource {
  Stream<List<DirectConversationModel>> watchUserConversations(String cpId);
  Future<DirectConversationModel?> findConversation(String cpId1, String cpId2);
  Future<DirectConversationModel> createConversation(
    String myCpId,
    String otherCpId,
  );
  Future<DirectConversationModel> findOrCreateConversation(
    String myCpId,
    String otherCpId,
  );
  Future<void> updateLastActivity(
    String conversationId,
    String lastMessage,
  );
  Future<void> markAsRead(String conversationId, String cpId);
  Future<void> incrementUnread(String conversationId, String cpId);
  Future<void> muteConversation(String conversationId, String cpId);
  Future<void> unmuteConversation(String conversationId, String cpId);
  Future<void> archiveConversation(String conversationId, String cpId);
  Future<void> unarchiveConversation(String conversationId, String cpId);
  Future<void> deleteConversationFor(String conversationId, String cpId);
}

/// Firestore implementation of ConversationsDataSource
class ConversationsFirestoreDataSource implements ConversationsDataSource {
  final FirebaseFirestore _firestore;

  ConversationsFirestoreDataSource(this._firestore);

  CollectionReference<Map<String, dynamic>> get _conversationsCollection =>
      _firestore.collection('direct_conversations');

  @override
  Stream<List<DirectConversationModel>> watchUserConversations(String cpId) {
    return _conversationsCollection
        .where('participantCpIds', arrayContains: cpId)
        .orderBy('lastActivityAt', descending: true)
        .snapshots()
        .map((snapshot) {
      try {
        return snapshot.docs
            .map((doc) => DirectConversationModel.fromFirestore(doc))
            .where((conv) => !conv.isDeletedFor(cpId)) // Filter out deleted
            .toList();
      } catch (e, stackTrace) {
        log('Error processing conversations stream: $e',
            stackTrace: stackTrace);
        return <DirectConversationModel>[];
      }
    }).handleError((error) {
      log('Error in conversations stream for user $cpId: $error');
      return <DirectConversationModel>[];
    });
  }

  @override
  Future<DirectConversationModel?> findConversation(
    String cpId1,
    String cpId2,
  ) async {
    try {
      final conversationId =
          DirectConversationModel.generateConversationId(cpId1, cpId2);
      final doc = await _conversationsCollection.doc(conversationId).get();

      if (!doc.exists) return null;

      return DirectConversationModel.fromFirestore(doc);
    } catch (e, stackTrace) {
      log('Error finding conversation: $e', stackTrace: stackTrace);
      return null;
    }
  }

  @override
  Future<DirectConversationModel> createConversation(
    String myCpId,
    String otherCpId,
  ) async {
    try {
      final conversationId =
          DirectConversationModel.generateConversationId(myCpId, otherCpId);
      final now = DateTime.now();

      final conversation = DirectConversationModel(
        id: conversationId,
        participantCpIds: [myCpId, otherCpId],
        lastMessage: null,
        lastActivityAt: now,
        unreadBy: {},
        mutedBy: [],
        archivedBy: [],
        deletedFor: [],
        createdAt: now,
        createdByCpId: myCpId,
      );

      await _conversationsCollection
          .doc(conversationId)
          .set(conversation.toFirestore());

      log('Created conversation $conversationId');
      return conversation;
    } catch (e, stackTrace) {
      log('Error creating conversation: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<DirectConversationModel> findOrCreateConversation(
    String myCpId,
    String otherCpId,
  ) async {
    // Try to find existing conversation
    final existing = await findConversation(myCpId, otherCpId);
    if (existing != null) {
      log('Found existing conversation: ${existing.id}');
      return existing;
    }

    // Create new conversation
    log('Creating new conversation between $myCpId and $otherCpId');
    return await createConversation(myCpId, otherCpId);
  }

  @override
  Future<void> updateLastActivity(
    String conversationId,
    String lastMessage,
  ) async {
    try {
      await _conversationsCollection.doc(conversationId).update({
        'lastMessage': lastMessage,
        'lastActivityAt': FieldValue.serverTimestamp(),
      });
      log('Updated last activity for conversation $conversationId');
    } catch (e, stackTrace) {
      log('Error updating last activity: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> markAsRead(String conversationId, String cpId) async {
    try {
      await _conversationsCollection.doc(conversationId).update({
        'unreadBy.$cpId': 0,
      });
      log('Marked conversation $conversationId as read for $cpId');
    } catch (e, stackTrace) {
      log('Error marking as read: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> incrementUnread(String conversationId, String cpId) async {
    try {
      await _conversationsCollection.doc(conversationId).update({
        'unreadBy.$cpId': FieldValue.increment(1),
      });
      log('Incremented unread for conversation $conversationId, user $cpId');
    } catch (e, stackTrace) {
      log('Error incrementing unread: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> muteConversation(String conversationId, String cpId) async {
    try {
      await _conversationsCollection.doc(conversationId).update({
        'mutedBy': FieldValue.arrayUnion([cpId]),
      });
      log('Muted conversation $conversationId for $cpId');
    } catch (e, stackTrace) {
      log('Error muting conversation: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> unmuteConversation(String conversationId, String cpId) async {
    try {
      await _conversationsCollection.doc(conversationId).update({
        'mutedBy': FieldValue.arrayRemove([cpId]),
      });
      log('Unmuted conversation $conversationId for $cpId');
    } catch (e, stackTrace) {
      log('Error unmuting conversation: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> archiveConversation(String conversationId, String cpId) async {
    try {
      await _conversationsCollection.doc(conversationId).update({
        'archivedBy': FieldValue.arrayUnion([cpId]),
      });
      log('Archived conversation $conversationId for $cpId');
    } catch (e, stackTrace) {
      log('Error archiving conversation: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> unarchiveConversation(String conversationId, String cpId) async {
    try {
      await _conversationsCollection.doc(conversationId).update({
        'archivedBy': FieldValue.arrayRemove([cpId]),
      });
      log('Unarchived conversation $conversationId for $cpId');
    } catch (e, stackTrace) {
      log('Error unarchiving conversation: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> deleteConversationFor(String conversationId, String cpId) async {
    try {
      await _conversationsCollection.doc(conversationId).update({
        'isDeletedFor': FieldValue.arrayUnion([cpId]),
      });
      log('Deleted conversation $conversationId for $cpId');
    } catch (e, stackTrace) {
      log('Error deleting conversation: $e', stackTrace: stackTrace);
      rethrow;
    }
  }
}
