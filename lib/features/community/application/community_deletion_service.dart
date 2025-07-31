import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'community_deletion_service.g.dart';

/// Service responsible for handling community data deletion during account deletion
///
/// This service implements a comprehensive soft-deletion strategy to maintain
/// data integrity while ensuring user privacy compliance. It handles:
/// - Community profiles
/// - Forum posts
/// - Comments
/// - Interactions (likes/dislikes)
/// - Future group memberships
class CommunityDeletionService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  // Collection references
  late final CollectionReference _communityProfiles;
  late final CollectionReference _forumPosts;
  late final CollectionReference _comments;
  late final CollectionReference _interactions;
  late final CollectionReference _communityInterest;

  CommunityDeletionService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance {
    _communityProfiles = _firestore.collection('communityProfiles');
    _forumPosts = _firestore.collection('forumPosts');
    _comments = _firestore.collection('comments');
    _interactions = _firestore.collection('interactions');
    _communityInterest = _firestore.collection('communityInterest');
  }

  /// Deletes all community-related data for a specific user
  ///
  /// This method handles bulk deletion of user's community data across all collections:
  /// - Community profile (soft delete)
  /// - Forum posts (soft delete)
  /// - Comments (soft delete)
  /// - Interactions/votes (soft delete)
  /// - Community interest tracking (hard delete)
  ///
  /// Uses batch operations for atomicity and performance optimization.
  /// All operations are logged for debugging and auditing purposes.
  ///
  /// [userUID] The Firebase Auth UID of the user being deleted
  ///
  /// Throws [Exception] if user is not authenticated or deletion fails
  Future<void> deleteUserCommunityData(String userUID) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null || currentUser.uid != userUID) {
      throw Exception('User not authenticated or UID mismatch');
    }

    print('DEBUG: Starting community data deletion for user: $userUID');

    try {
      // First, get the community profile by userUID
      final profile = await _getCommunityProfileByUserUID(userUID);
      if (profile == null) {
        print('DEBUG: No community profile found for user $userUID');
        return;
      }

      final communityProfileId = profile.id;
      print(
          'DEBUG: Found community profile ID: $communityProfileId for user: $userUID');

      // Use batch operations for atomicity across collections
      final batch = _firestore.batch();
      int operationCount = 0;

      // Step 1: Soft delete community profile
      await _softDeleteCommunityProfile(batch, communityProfileId);
      operationCount++;

      // Step 2: Soft delete all user posts
      final postsCount = await _softDeleteUserPosts(batch, communityProfileId);
      operationCount += postsCount;

      // Step 3: Soft delete all user comments
      final commentsCount =
          await _softDeleteUserComments(batch, communityProfileId);
      operationCount += commentsCount;

      // Step 4: Soft delete all user interactions
      final interactionsCount =
          await _softDeleteUserInteractions(batch, communityProfileId);
      operationCount += interactionsCount;

      // Step 5: Delete community interest tracking (if exists)
      await _deleteCommunityInterest(batch, userUID); // Still uses userUID
      operationCount++;

      print(
          'DEBUG: Prepared $operationCount batch operations for community data deletion');

      // Execute all operations atomically
      if (operationCount > 0) {
        await batch.commit();
        print('DEBUG: Successfully executed community data deletion batch');
      } else {
        print('DEBUG: No community data found for user $userUID');
      }
    } catch (e) {
      print('ERROR: Community data deletion failed for user $userUID: $e');
      throw Exception('Failed to delete community data: $e');
    }
  }

  /// Soft deletes the user's community profile
  Future<void> _softDeleteCommunityProfile(
      WriteBatch batch, String communityProfileId) async {
    final profileDoc = _communityProfiles.doc(communityProfileId);
    final profileSnapshot = await profileDoc.get();

    if (profileSnapshot.exists) {
      batch.update(profileDoc, {
        'isDeleted': true,
        'updatedAt': FieldValue.serverTimestamp(),
        // Optionally anonymize sensitive data
        'displayName': '[Deleted User]',
        'avatarUrl': null,
      });
      print('DEBUG: Prepared community profile soft deletion');
    } else {
      print('DEBUG: No community profile found with ID $communityProfileId');
    }
  }

  /// Soft deletes all posts authored by the user
  Future<int> _softDeleteUserPosts(
      WriteBatch batch, String communityProfileId) async {
    final postsQuery = await _forumPosts
        .where('authorCPId', isEqualTo: communityProfileId)
        .where('isDeleted', isEqualTo: false)
        .get();

    int count = 0;
    for (final doc in postsQuery.docs) {
      batch.update(doc.reference, {
        'isDeleted': true,
        'updatedAt': FieldValue.serverTimestamp(),
        // Optionally anonymize content
        'title': '[Post by deleted user]',
        'body':
            '[This post was created by a user who has deleted their account]',
      });
      count++;
    }

    print('DEBUG: Prepared $count posts for soft deletion');
    return count;
  }

  /// Soft deletes all comments authored by the user
  Future<int> _softDeleteUserComments(
      WriteBatch batch, String communityProfileId) async {
    final commentsQuery = await _comments
        .where('authorCPId', isEqualTo: communityProfileId)
        .get();

    int count = 0;
    for (final doc in commentsQuery.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final isAlreadyDeleted = data['isDeleted'] ?? false;

      if (!isAlreadyDeleted) {
        batch.update(doc.reference, {
          'isDeleted': true,
          'updatedAt': FieldValue.serverTimestamp(),
          // Anonymize content but preserve structure for thread continuity
          'body': '[Comment by deleted user]',
        });
        count++;
      }
    }

    print('DEBUG: Prepared $count comments for soft deletion');
    return count;
  }

  /// Soft deletes all interactions (likes/dislikes) by the user
  Future<int> _softDeleteUserInteractions(
      WriteBatch batch, String communityProfileId) async {
    final interactionsQuery = await _interactions
        .where('userCPId', isEqualTo: communityProfileId)
        .get();

    int count = 0;
    for (final doc in interactionsQuery.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final isAlreadyDeleted = data['isDeleted'] ?? false;

      if (!isAlreadyDeleted) {
        batch.update(doc.reference, {
          'isDeleted': true,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        count++;
      }
    }

    print('DEBUG: Prepared $count interactions for soft deletion');
    return count;
  }

  /// Deletes community interest tracking data (hard delete for analytics)
  Future<void> _deleteCommunityInterest(
      WriteBatch batch, String userUID) async {
    final interestDoc = _communityInterest.doc(userUID);
    final interestSnapshot = await interestDoc.get();

    if (interestSnapshot.exists) {
      batch.delete(interestDoc);
      print('DEBUG: Prepared community interest data for deletion');
    }
  }

  /// Helper method to get community profile by userUID
  Future<DocumentSnapshot?> _getCommunityProfileByUserUID(
      String userUID) async {
    try {
      final snapshot = await _communityProfiles
          .where('userUID', isEqualTo: userUID)
          .where('isDeleted', isEqualTo: false)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      return snapshot.docs.first;
    } catch (e) {
      print('ERROR: Failed to get community profile for user $userUID: $e');
      return null;
    }
  }

  /// Checks if user has any community data that needs deletion
  ///
  /// This can be used to determine if community deletion is necessary
  /// before executing the full deletion process
  Future<bool> hasUserCommunityData(String userUID) async {
    try {
      // First get the community profile ID
      final profile = await _getCommunityProfileByUserUID(userUID);
      if (profile == null) {
        return false; // No community profile found
      }

      // Check community profile
      final profileSnapshot = await _communityProfiles.doc(profile.id).get();
      if (profileSnapshot.exists) {
        final data = profileSnapshot.data() as Map<String, dynamic>?;
        if (data != null && !(data['isDeleted'] ?? false)) {
          return true;
        }
      }

      // Check posts
      final postsQuery = await _forumPosts
          .where('authorCPId', isEqualTo: profile.id)
          .limit(1)
          .get();
      if (postsQuery.docs.isNotEmpty) return true;

      // Check comments
      final commentsQuery = await _comments
          .where('authorCPId', isEqualTo: profile.id)
          .limit(1)
          .get();
      if (commentsQuery.docs.isNotEmpty) return true;

      // Check interactions
      final interactionsQuery = await _interactions
          .where('userCPId', isEqualTo: profile.id)
          .limit(1)
          .get();
      if (interactionsQuery.docs.isNotEmpty) return true;

      return false;
    } catch (e) {
      print('ERROR: Failed to check user community data: $e');
      return true; // Assume data exists if check fails
    }
  }

  /// Gets a summary of community data for the user (for logging/analytics)
  Future<Map<String, int>> getCommunityDataSummary(String userUID) async {
    final summary = <String, int>{
      'profiles': 0,
      'posts': 0,
      'comments': 0,
      'interactions': 0,
    };

    try {
      // First get the community profile ID
      final profile = await _getCommunityProfileByUserUID(userUID);
      if (profile == null) {
        return summary; // No community profile found
      }

      // Count profile
      final profileSnapshot = await _communityProfiles.doc(profile.id).get();
      summary['profiles'] = profileSnapshot.exists ? 1 : 0;

      // Count posts
      final postsQuery =
          await _forumPosts.where('authorCPId', isEqualTo: profile.id).get();
      summary['posts'] = postsQuery.docs.length;

      // Count comments
      final commentsQuery =
          await _comments.where('authorCPId', isEqualTo: profile.id).get();
      summary['comments'] = commentsQuery.docs.length;

      // Count interactions
      final interactionsQuery =
          await _interactions.where('userCPId', isEqualTo: profile.id).get();
      summary['interactions'] = interactionsQuery.docs.length;
    } catch (e) {
      print('ERROR: Failed to get community data summary: $e');
    }

    return summary;
  }
}

@riverpod
CommunityDeletionService communityDeletionService(Ref ref) {
  return CommunityDeletionService();
}
