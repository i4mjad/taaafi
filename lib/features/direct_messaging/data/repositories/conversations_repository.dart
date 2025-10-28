import '../../domain/entities/direct_conversation_entity.dart';
import '../datasources/conversations_firestore_datasource.dart';
import '../models/direct_conversation_model.dart';

/// Repository for conversation operations
class ConversationsRepository {
  final ConversationsDataSource _dataSource;

  ConversationsRepository(this._dataSource);

  /// Watch user's conversations (real-time stream)
  Stream<List<DirectConversationEntity>> watchUserConversations(String cpId) {
    return _dataSource
        .watchUserConversations(cpId)
        .map((models) => models.cast<DirectConversationEntity>());
  }

  /// Find existing conversation between two users
  Future<DirectConversationEntity?> findConversation(
    String cpId1,
    String cpId2,
  ) async {
    final model = await _dataSource.findConversation(cpId1, cpId2);
    return model;
  }

  /// Create a new conversation
  Future<DirectConversationEntity> createConversation(
    String myCpId,
    String otherCpId,
  ) async {
    final model = await _dataSource.createConversation(myCpId, otherCpId);
    return model;
  }

  /// Find or create conversation (idempotent)
  Future<DirectConversationEntity> findOrCreateConversation(
    String myCpId,
    String otherCpId,
  ) async {
    final model = await _dataSource.findOrCreateConversation(myCpId, otherCpId);
    return model;
  }

  /// Update last activity with new message
  Future<void> updateLastActivity(
    String conversationId,
    String lastMessage,
  ) async {
    await _dataSource.updateLastActivity(conversationId, lastMessage);
  }

  /// Mark conversation as read
  Future<void> markAsRead(String conversationId, String cpId) async {
    await _dataSource.markAsRead(conversationId, cpId);
  }

  /// Increment unread count
  Future<void> incrementUnread(String conversationId, String cpId) async {
    await _dataSource.incrementUnread(conversationId, cpId);
  }

  /// Mute conversation
  Future<void> muteConversation(String conversationId, String cpId) async {
    await _dataSource.muteConversation(conversationId, cpId);
  }

  /// Unmute conversation
  Future<void> unmuteConversation(String conversationId, String cpId) async {
    await _dataSource.unmuteConversation(conversationId, cpId);
  }

  /// Archive conversation
  Future<void> archiveConversation(String conversationId, String cpId) async {
    await _dataSource.archiveConversation(conversationId, cpId);
  }

  /// Unarchive conversation
  Future<void> unarchiveConversation(String conversationId, String cpId) async {
    await _dataSource.unarchiveConversation(conversationId, cpId);
  }

  /// Delete conversation for user (soft delete)
  Future<void> deleteConversationFor(String conversationId, String cpId) async {
    await _dataSource.deleteConversationFor(conversationId, cpId);
  }
}

/// Factory for creating ConversationsRepository
class ConversationsRepositoryFactory {
  static ConversationsRepository create(ConversationsDataSource dataSource) {
    return ConversationsRepository(dataSource);
  }
}


