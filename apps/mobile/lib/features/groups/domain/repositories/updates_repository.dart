import '../entities/group_update_entity.dart';
import '../entities/update_comment_entity.dart';

/// Repository interface for managing group updates and comments
abstract class UpdatesRepository {
  // ==================== UPDATE CRUD ====================
  
  /// Create a new update
  Future<String> createUpdate(GroupUpdateEntity update);

  /// Get an update by ID
  Future<GroupUpdateEntity?> getUpdateById(String updateId);

  /// Update an existing update
  Future<void> updateUpdate(GroupUpdateEntity update);

  /// Delete an update
  Future<void> deleteUpdate(String updateId);

  // ==================== UPDATE QUERIES ====================
  
  /// Get all updates for a group (real-time stream)
  Stream<List<GroupUpdateEntity>> getGroupUpdates(String groupId);

  /// Get recent updates with limit (for initial load / pagination)
  Future<List<GroupUpdateEntity>> getRecentUpdates(
    String groupId, {
    int limit = 20,
    DateTime? before, // For pagination
  });

  /// Get updates by a specific user in a group
  Future<List<GroupUpdateEntity>> getUserUpdates(
    String groupId,
    String cpId, {
    int limit = 20,
  });

  /// Get updates by type
  Future<List<GroupUpdateEntity>> getUpdatesByType(
    String groupId,
    UpdateType type, {
    int limit = 20,
  });

  /// Get pinned updates for a group
  Future<List<GroupUpdateEntity>> getPinnedUpdates(String groupId);

  /// Get latest N updates (for real-time feed in group screen)
  Stream<List<GroupUpdateEntity>> getLatestUpdates(
    String groupId, {
    int limit = 5,
  });

  // ==================== REACTIONS ====================
  
  /// Toggle reaction on an update
  Future<void> toggleUpdateReaction(
    String updateId,
    String cpId,
    String emoji,
  );

  // ==================== COMMENTS ====================
  
  /// Add a comment to an update
  Future<String> addComment(UpdateCommentEntity comment);

  /// Delete a comment
  Future<void> deleteComment(String commentId, String updateId);

  /// Get all comments for an update (real-time stream)
  Stream<List<UpdateCommentEntity>> getUpdateComments(String updateId);

  /// Get comment count for an update
  Future<int> getCommentCount(String updateId);

  /// Toggle reaction on a comment
  Future<void> toggleCommentReaction(
    String commentId,
    String cpId,
    String emoji,
  );

  // ==================== MODERATION ====================
  
  /// Hide an update (admin only)
  Future<void> hideUpdate(String updateId, String adminCpId);

  /// Unhide an update (admin only)
  Future<void> unhideUpdate(String updateId, String adminCpId);

  /// Pin an update (admin only)
  Future<void> pinUpdate(String updateId, String adminCpId);

  /// Unpin an update (admin only)
  Future<void> unpinUpdate(String updateId, String adminCpId);

  // ==================== STATISTICS ====================
  
  /// Get total update count for a group
  Future<int> getUpdateCount(String groupId);

  /// Get total update count for a user in a group
  Future<int> getUserUpdateCount(String groupId, String cpId);
}

