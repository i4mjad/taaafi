import '../../domain/entities/direct_message_entity.dart';
import '../datasources/direct_messages_firestore_datasource.dart';
import '../models/direct_message_model.dart';

/// Repository for direct chat operations
class DirectChatRepository {
  final DirectMessagesDataSource _dataSource;

  DirectChatRepository(this._dataSource);

  /// Watch messages in a conversation (real-time stream)
  Stream<List<DirectMessageEntity>> watchMessages(String conversationId) {
    return _dataSource
        .watchMessages(conversationId)
        .map((models) => models.cast<DirectMessageEntity>());
  }

  /// Load paginated messages
  Future<PaginatedMessagesResult> loadMessages(
    String conversationId,
    MessagePaginationParams params,
  ) async {
    return await _dataSource.loadMessages(conversationId, params);
  }

  /// Send a message
  Future<void> sendMessage(DirectMessageEntity message) async {
    final model = DirectMessageModel.fromEntity(message);
    await _dataSource.sendMessage(model);
  }

  /// Delete a message (soft delete)
  Future<void> deleteMessage(String conversationId, String messageId) async {
    await _dataSource.deleteMessage(conversationId, messageId);
  }

  /// Hide a message (moderation)
  Future<void> hideMessage(String conversationId, String messageId) async {
    await _dataSource.hideMessage(conversationId, messageId);
  }

  /// Clear cache for a conversation
  void clearCache(String conversationId) {
    _dataSource.clearCache(conversationId);
  }
}

/// Factory for creating DirectChatRepository
class DirectChatRepositoryFactory {
  static DirectChatRepository create(DirectMessagesDataSource dataSource) {
    return DirectChatRepository(dataSource);
  }
}


