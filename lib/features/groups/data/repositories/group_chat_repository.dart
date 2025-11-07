import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../domain/entities/group_message_entity.dart';
import '../datasources/group_messages_firestore_datasource.dart';
import '../datasources/groups_datasource.dart';
import '../models/group_message_model.dart';

/// Repository for group chat operations
///
/// Provides domain-level interface for chat functionality
/// Handles entity/model conversion and error handling
abstract class GroupChatRepository {
  /// Watch messages for a group with real-time updates
  Stream<List<GroupMessageEntity>> watchMessages(String groupId);

  /// Load messages with pagination for lazy loading
  Future<PaginatedMessagesEntityResult> loadMessages(
    String groupId,
    MessagePaginationEntityParams params,
  );

  /// Send a new message to a group
  Future<void> sendMessage(GroupMessageEntity message);

  /// Delete a message (soft delete)
  Future<void> deleteMessage(String groupId, String messageId);

  /// Hide a message (moderation action)
  Future<void> hideMessage(String groupId, String messageId);

  /// Unhide a message (moderation action)
  Future<void> unhideMessage(String groupId, String messageId);

  /// Clear cache for performance management
  void clearCache(String groupId);

  /// Clear all cache
  void clearAllCache();

  /// Get DocumentSnapshot by message ID for pagination
  DocumentSnapshot? getDocumentSnapshot(String messageId);

  /// Get sender display name respecting anonymity (from cache)
  String getSenderDisplayName(String cpId);

  /// Get sender avatar color (consistent per user)
  Color getSenderAvatarColor(String cpId);

  /// Get sender anonymity status
  bool getSenderAnonymity(String cpId);

  /// Get sender avatar URL (for non-anonymous users)
  String? getSenderAvatarUrl(String cpId);

  /// Clear profile cache for specific user (when profile is updated)
  void clearProfileCache(String cpId);
}

/// Domain-level pagination parameters
class MessagePaginationEntityParams {
  final int limit;
  final String? startAfterId;
  final bool descending;

  const MessagePaginationEntityParams({
    this.limit = 20,
    this.startAfterId,
    this.descending = true,
  });

  MessagePaginationEntityParams copyWith({
    int? limit,
    String? startAfterId,
    bool? descending,
  }) {
    return MessagePaginationEntityParams(
      limit: limit ?? this.limit,
      startAfterId: startAfterId ?? this.startAfterId,
      descending: descending ?? this.descending,
    );
  }
}

/// Domain-level pagination result
class PaginatedMessagesEntityResult {
  final List<GroupMessageEntity> messages;
  final String? lastMessageId;
  final bool hasMore;

  const PaginatedMessagesEntityResult({
    required this.messages,
    this.lastMessageId,
    required this.hasMore,
  });
}

/// Implementation of GroupChatRepository using Firestore
class GroupChatRepositoryImpl implements GroupChatRepository {
  final GroupMessagesDataSource _dataSource;
  final GroupsDataSource? _groupsDataSource; // For activity tracking (Sprint 2)

  GroupChatRepositoryImpl(this._dataSource, {GroupsDataSource? groupsDataSource})
      : _groupsDataSource = groupsDataSource;

  @override
  Stream<List<GroupMessageEntity>> watchMessages(String groupId) {
    try {
      return _dataSource.watchMessages(groupId).map((models) {
        return models.map((model) => model.toEntity()).toList();
      }).handleError((error) {
        log('Error in repository watchMessages for group $groupId: $error');
        return <GroupMessageEntity>[];
      });
    } catch (e, stackTrace) {
      log('Error setting up message stream for group $groupId: $e',
          stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<PaginatedMessagesEntityResult> loadMessages(
    String groupId,
    MessagePaginationEntityParams params,
  ) async {
    try {
      // Convert domain params to data layer params
      DocumentSnapshot? startAfterDoc;
      if (params.startAfterId != null) {
        startAfterDoc = _dataSource.getDocumentSnapshot(params.startAfterId!);
      }

      final dataParams = MessagePaginationParams(
        limit: params.limit,
        startAfter: startAfterDoc, // Use cached DocumentSnapshot for pagination
        descending: params.descending,
      );

      final result = await _dataSource.loadMessages(groupId, dataParams);

      // Convert back to domain entities
      return PaginatedMessagesEntityResult(
        messages: result.messages.map((model) => model.toEntity()).toList(),
        lastMessageId: result.lastDocument?.id,
        hasMore: result.hasMore,
      );
    } catch (e, stackTrace) {
      log('Error loading messages for group $groupId: $e',
          stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> sendMessage(GroupMessageEntity message) async {
    try {
      // TODO: Add tokenization for search functionality
      final tokens = _generateTokens(message.body);

      // Convert entity to model with generated tokens
      final model =
          GroupMessageModel.fromEntity(message.copyWith(tokens: tokens));

      await _dataSource.sendMessage(model);
      log('Message sent via repository for group ${message.groupId}');

      // Update member activity tracking (Sprint 2 - Feature 2.1)
      if (_groupsDataSource != null) {
        try {
          await _groupsDataSource!.updateMemberActivity(
            groupId: message.groupId,
            cpId: message.senderCpId,
          );
          log('Activity updated for member ${message.senderCpId}');
        } catch (e) {
          // Don't fail message send if activity update fails
          log('Failed to update activity (non-critical): $e');
        }
      }
    } catch (e, stackTrace) {
      log('Error sending message via repository: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> deleteMessage(String groupId, String messageId) async {
    try {
      await _dataSource.deleteMessage(groupId, messageId);
      log('Message deleted via repository: $messageId');
    } catch (e, stackTrace) {
      log('Error deleting message via repository: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> hideMessage(String groupId, String messageId) async {
    try {
      await _dataSource.hideMessage(groupId, messageId);
      log('Message hidden via repository: $messageId');
    } catch (e, stackTrace) {
      log('Error hiding message via repository: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> unhideMessage(String groupId, String messageId) async {
    try {
      await _dataSource.unhideMessage(groupId, messageId);
      log('Message unhidden via repository: $messageId');
    } catch (e, stackTrace) {
      log('Error unhiding message via repository: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  void clearCache(String groupId) {
    _dataSource.clearCache(groupId);
    log('Cache cleared via repository for group $groupId');
  }

  @override
  void clearAllCache() {
    _dataSource.clearAllCache();
    log('All cache cleared via repository');
  }

  @override
  DocumentSnapshot? getDocumentSnapshot(String messageId) {
    return _dataSource.getDocumentSnapshot(messageId);
  }

  @override
  String getSenderDisplayName(String cpId) {
    if (_dataSource is GroupMessagesFirestoreDataSource) {
      return (_dataSource as GroupMessagesFirestoreDataSource)
          .getSenderDisplayName(cpId);
    }
    return 'مجهول'; // Fallback
  }

  @override
  Color getSenderAvatarColor(String cpId) {
    if (_dataSource is GroupMessagesFirestoreDataSource) {
      return (_dataSource as GroupMessagesFirestoreDataSource)
          .getSenderAvatarColor(cpId);
    }
    return Colors.blue; // Fallback
  }

  @override
  bool getSenderAnonymity(String cpId) {
    if (_dataSource is GroupMessagesFirestoreDataSource) {
      return (_dataSource as GroupMessagesFirestoreDataSource)
          .getSenderAnonymity(cpId);
    }
    return true; // Fallback
  }

  @override
  String? getSenderAvatarUrl(String cpId) {
    if (_dataSource is GroupMessagesFirestoreDataSource) {
      return (_dataSource as GroupMessagesFirestoreDataSource)
          .getSenderAvatarUrl(cpId);
    }
    return null; // Fallback
  }

  @override
  void clearProfileCache(String cpId) {
    if (_dataSource is GroupMessagesFirestoreDataSource) {
      (_dataSource as GroupMessagesFirestoreDataSource).clearProfileCache(cpId);
    }
    log('Profile cache cleared via repository for cpId: $cpId');
  }

  /// Generate search tokens from message body
  /// TODO: Implement proper Arabic-aware tokenization
  List<String> _generateTokens(String body) {
    // Basic tokenization - split by spaces and common punctuation
    // TODO: Replace with proper Arabic/English tokenization service
    final tokens = body
        .toLowerCase()
        .split(RegExp(r'[\s\p{P}]+', unicode: true))
        .where((token) => token.isNotEmpty && token.length > 2)
        .toSet() // Remove duplicates
        .toList();

    log('Generated ${tokens.length} tokens from message body');
    return tokens;
  }
}

/// Factory for creating GroupChatRepository instances
class GroupChatRepositoryFactory {
  static GroupChatRepository create(GroupMessagesDataSource dataSource) {
    return GroupChatRepositoryImpl(dataSource);
  }
}
