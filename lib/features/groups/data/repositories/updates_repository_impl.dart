import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/repositories/updates_repository.dart';
import '../../domain/entities/group_update_entity.dart';
import '../../domain/entities/update_comment_entity.dart';
import '../models/group_update_model.dart';
import '../models/update_comment_model.dart';

/// Implementation of UpdatesRepository using Firestore
class UpdatesRepositoryImpl implements UpdatesRepository {
  final FirebaseFirestore _firestore;

  UpdatesRepositoryImpl(this._firestore);

  CollectionReference get _updatesCollection =>
      _firestore.collection('group_updates');

  CollectionReference get _commentsCollection =>
      _firestore.collection('update_comments');

  void log(String message, {StackTrace? stackTrace}) {
    developer.log(
      message,
      name: 'UpdatesRepository',
      stackTrace: stackTrace,
    );
  }

  // ==================== UPDATE CRUD ====================

  @override
  Future<String> createUpdate(GroupUpdateEntity update) async {
    try {
      log('Creating update in group ${update.groupId}');

      final docRef = _updatesCollection.doc();
      // TODO: Get locale from user profile or device
      final model = GroupUpdateModel.fromEntity(update.copyWith(
        id: docRef.id,
        locale: update.locale.isEmpty ? 'en' : update.locale,
      ));

      await docRef.set(model.toFirestore());

      log('Update created successfully: ${docRef.id}');
      return docRef.id;
    } catch (e, stackTrace) {
      log('Error creating update: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<GroupUpdateEntity?> getUpdateById(String updateId) async {
    try {
      log('Getting update by ID: $updateId');

      final doc = await _updatesCollection.doc(updateId).get();
      if (!doc.exists) {
        log('Update not found: $updateId');
        return null;
      }

      return GroupUpdateModel.fromFirestore(doc).toEntity();
    } catch (e, stackTrace) {
      log('Error getting update: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> updateUpdate(GroupUpdateEntity update) async {
    try {
      log('Updating update: ${update.id}');

      final model = GroupUpdateModel.fromEntity(update);
      await _updatesCollection.doc(update.id).update(model.toFirestore());

      log('Update updated successfully');
    } catch (e, stackTrace) {
      log('Error updating update: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> deleteUpdate(String updateId) async {
    try {
      log('Deleting update: $updateId');

      // Delete the update
      await _updatesCollection.doc(updateId).delete();

      // Also delete all comments for this update
      final commentsSnapshot = await _commentsCollection
          .where('updateId', isEqualTo: updateId)
          .get();

      final batch = _firestore.batch();
      for (final doc in commentsSnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      log('Update and its comments deleted successfully');
    } catch (e, stackTrace) {
      log('Error deleting update: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  // ==================== UPDATE QUERIES ====================

  @override
  Stream<List<GroupUpdateEntity>> getGroupUpdates(String groupId) {
    try {
      log('Streaming updates for group: $groupId');

      return _updatesCollection
          .where('groupId', isEqualTo: groupId)
          .where('isHidden', isEqualTo: false)
          .orderBy('isPinned', descending: true)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => GroupUpdateModel.fromFirestore(doc).toEntity())
            .toList();
      });
    } catch (e, stackTrace) {
      log('Error streaming group updates: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<List<GroupUpdateEntity>> getRecentUpdates(
    String groupId, {
    int limit = 20,
    DateTime? before,
  }) async {
    try {
      log('Getting recent updates for group: $groupId (limit: $limit)');

      Query query = _updatesCollection
          .where('groupId', isEqualTo: groupId)
          .where('isHidden', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (before != null) {
        query =
            query.where('createdAt', isLessThan: Timestamp.fromDate(before));
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => GroupUpdateModel.fromFirestore(doc).toEntity())
          .toList();
    } catch (e, stackTrace) {
      log('Error getting recent updates: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<List<GroupUpdateEntity>> getUserUpdates(
    String groupId,
    String cpId, {
    int limit = 20,
  }) async {
    try {
      log('Getting updates for user $cpId in group $groupId');

      final snapshot = await _updatesCollection
          .where('groupId', isEqualTo: groupId)
          .where('authorCpId', isEqualTo: cpId)
          .where('isHidden', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => GroupUpdateModel.fromFirestore(doc).toEntity())
          .toList();
    } catch (e, stackTrace) {
      log('Error getting user updates: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<List<GroupUpdateEntity>> getUpdatesByType(
    String groupId,
    UpdateType type, {
    int limit = 20,
  }) async {
    try {
      log('Getting updates of type ${type.toFirestore()} in group $groupId');

      final snapshot = await _updatesCollection
          .where('groupId', isEqualTo: groupId)
          .where('type', isEqualTo: type.toFirestore())
          .where('isHidden', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => GroupUpdateModel.fromFirestore(doc).toEntity())
          .toList();
    } catch (e, stackTrace) {
      log('Error getting updates by type: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<List<GroupUpdateEntity>> getPinnedUpdates(String groupId) async {
    try {
      log('Getting pinned updates for group: $groupId');

      final snapshot = await _updatesCollection
          .where('groupId', isEqualTo: groupId)
          .where('isPinned', isEqualTo: true)
          .where('isHidden', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .limit(3) // Max 3 pinned updates
          .get();

      return snapshot.docs
          .map((doc) => GroupUpdateModel.fromFirestore(doc).toEntity())
          .toList();
    } catch (e, stackTrace) {
      log('Error getting pinned updates: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Stream<List<GroupUpdateEntity>> getLatestUpdates(
    String groupId, {
    int limit = 5,
  }) {
    try {
      log('Streaming latest $limit updates for group: $groupId');

      return _updatesCollection
          .where('groupId', isEqualTo: groupId)
          .where('isHidden', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => GroupUpdateModel.fromFirestore(doc).toEntity())
            .toList();
      });
    } catch (e, stackTrace) {
      log('Error streaming latest updates: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  // ==================== REACTIONS ====================

  @override
  Future<void> toggleUpdateReaction(
    String updateId,
    String cpId,
    String emoji,
  ) async {
    try {
      log('Toggling reaction $emoji on update $updateId by $cpId');

      final updateDoc = await _updatesCollection.doc(updateId).get();
      if (!updateDoc.exists) {
        throw Exception('Update not found');
      }

      final updateData = updateDoc.data() as Map<String, dynamic>;
      final currentReactions =
          GroupUpdateModel.fromFirestore(updateDoc).reactions;

      // Toggle logic: if user already reacted with this emoji, remove it; otherwise add it
      final emojiReactions = List<String>.from(currentReactions[emoji] ?? []);

      if (emojiReactions.contains(cpId)) {
        emojiReactions.remove(cpId);
        log('Removing reaction $emoji from user $cpId');
      } else {
        emojiReactions.add(cpId);
        log('Adding reaction $emoji from user $cpId');
      }

      // Update reactions map
      final updatedReactions = Map<String, dynamic>.from(currentReactions);
      if (emojiReactions.isEmpty) {
        updatedReactions.remove(emoji);
      } else {
        updatedReactions[emoji] = emojiReactions;
      }

      // Update support count if emoji is a support reaction (❤️, 🤲, 💪)
      final supportEmojis = ['❤️', '🤲', '💪', '🙏'];
      int supportCount = 0;
      updatedReactions.forEach((emoji, cpIds) {
        if (supportEmojis.contains(emoji) && cpIds is List) {
          supportCount += cpIds.length;
        }
      });

      // Update update document
      await _updatesCollection.doc(updateId).update({
        'reactions': updatedReactions,
        'supportCount': supportCount,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      log('Reaction toggled successfully');
    } catch (e, stackTrace) {
      log('Error toggling update reaction: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  // ==================== COMMENTS ====================

  @override
  Future<String> addComment(UpdateCommentEntity comment) async {
    try {
      log('Adding comment to update ${comment.updateId}');

      final docRef = _commentsCollection.doc();
      final model = UpdateCommentModel.fromEntity(
        comment.copyWith(id: docRef.id),
      );

      await docRef.set(model.toFirestore());

      // Increment comment count on update
      await _updatesCollection.doc(comment.updateId).update({
        'commentCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      log('Comment added successfully: ${docRef.id}');
      return docRef.id;
    } catch (e, stackTrace) {
      log('Error adding comment: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> deleteComment(String commentId, String updateId) async {
    try {
      log('Deleting comment: $commentId');

      await _commentsCollection.doc(commentId).delete();

      // Decrement comment count on update
      await _updatesCollection.doc(updateId).update({
        'commentCount': FieldValue.increment(-1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      log('Comment deleted successfully');
    } catch (e, stackTrace) {
      log('Error deleting comment: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Stream<List<UpdateCommentEntity>> getUpdateComments(String updateId) {
    try {
      log('Streaming comments for update: $updateId');

      return _commentsCollection
          .where('updateId', isEqualTo: updateId)
          .where('isHidden', isEqualTo: false)
          .orderBy('createdAt', descending: false)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => UpdateCommentModel.fromFirestore(doc).toEntity())
            .toList();
      });
    } catch (e, stackTrace) {
      log('Error streaming update comments: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<int> getCommentCount(String updateId) async {
    try {
      log('Getting comment count for update: $updateId');

      final snapshot = await _commentsCollection
          .where('updateId', isEqualTo: updateId)
          .where('isHidden', isEqualTo: false)
          .get();

      return snapshot.docs.length;
    } catch (e, stackTrace) {
      log('Error getting comment count: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> toggleCommentReaction(
    String commentId,
    String cpId,
    String emoji,
  ) async {
    try {
      log('Toggling reaction $emoji on comment $commentId by $cpId');

      final commentDoc = await _commentsCollection.doc(commentId).get();
      if (!commentDoc.exists) {
        throw Exception('Comment not found');
      }

      final currentReactions =
          UpdateCommentModel.fromFirestore(commentDoc).reactions;

      // Toggle logic
      final emojiReactions = List<String>.from(currentReactions[emoji] ?? []);

      if (emojiReactions.contains(cpId)) {
        emojiReactions.remove(cpId);
      } else {
        emojiReactions.add(cpId);
      }

      // Update reactions map
      final updatedReactions = Map<String, dynamic>.from(currentReactions);
      if (emojiReactions.isEmpty) {
        updatedReactions.remove(emoji);
      } else {
        updatedReactions[emoji] = emojiReactions;
      }

      // Update comment document
      await _commentsCollection.doc(commentId).update({
        'reactions': updatedReactions,
      });

      log('Comment reaction toggled successfully');
    } catch (e, stackTrace) {
      log('Error toggling comment reaction: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  // ==================== MODERATION ====================

  @override
  Future<void> hideUpdate(String updateId, String adminCpId) async {
    try {
      log('Hiding update $updateId by admin $adminCpId');

      await _updatesCollection.doc(updateId).update({
        'isHidden': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      log('Update hidden successfully');
    } catch (e, stackTrace) {
      log('Error hiding update: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> unhideUpdate(String updateId, String adminCpId) async {
    try {
      log('Unhiding update $updateId by admin $adminCpId');

      await _updatesCollection.doc(updateId).update({
        'isHidden': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      log('Update unhidden successfully');
    } catch (e, stackTrace) {
      log('Error unhiding update: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> pinUpdate(String updateId, String adminCpId) async {
    try {
      log('Pinning update $updateId by admin $adminCpId');

      // Check if group already has 3 pinned updates
      final update = await getUpdateById(updateId);
      if (update == null) {
        throw Exception('Update not found');
      }

      final pinnedUpdates = await getPinnedUpdates(update.groupId);
      if (pinnedUpdates.length >= 3) {
        throw Exception('Maximum 3 pinned updates allowed');
      }

      await _updatesCollection.doc(updateId).update({
        'isPinned': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      log('Update pinned successfully');
    } catch (e, stackTrace) {
      log('Error pinning update: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> unpinUpdate(String updateId, String adminCpId) async {
    try {
      log('Unpinning update $updateId by admin $adminCpId');

      await _updatesCollection.doc(updateId).update({
        'isPinned': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      log('Update unpinned successfully');
    } catch (e, stackTrace) {
      log('Error unpinning update: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  // ==================== STATISTICS ====================

  @override
  Future<int> getUpdateCount(String groupId) async {
    try {
      log('Getting update count for group: $groupId');

      final snapshot = await _updatesCollection
          .where('groupId', isEqualTo: groupId)
          .where('isHidden', isEqualTo: false)
          .get();

      return snapshot.docs.length;
    } catch (e, stackTrace) {
      log('Error getting update count: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<int> getUserUpdateCount(String groupId, String cpId) async {
    try {
      log('Getting update count for user $cpId in group $groupId');

      final snapshot = await _updatesCollection
          .where('groupId', isEqualTo: groupId)
          .where('authorCpId', isEqualTo: cpId)
          .where('isHidden', isEqualTo: false)
          .get();

      return snapshot.docs.length;
    } catch (e, stackTrace) {
      log('Error getting user update count: $e', stackTrace: stackTrace);
      rethrow;
    }
  }
}
