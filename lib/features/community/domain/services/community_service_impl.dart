import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../entities/community_profile_entity.dart';
import '../repositories/community_repository.dart';
import '../../data/exceptions/community_exceptions.dart';
import 'community_service.dart';

/// Implementation of community service
///
/// This service implements the business logic for community profile management.
/// It handles validation, authentication checks, and coordinates with the repository layer.
class CommunityServiceImpl implements CommunityService {
  final CommunityRepository _repository;
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  /// Cache for interest recording to avoid duplicate calls
  bool _hasRecordedInterest = false;

  CommunityServiceImpl(this._repository, this._auth, this._firestore);

  @override
  Future<CommunityProfileEntity> createProfile({
    required String displayName,
    required String gender,
    required bool isAnonymous,
    String? avatarUrl,
  }) async {
    // Check authentication
    final user = _auth.currentUser;
    if (user == null) {
      throw const AuthenticationException('User not authenticated');
    }

    // Validate input data
    _validateProfileData(displayName, gender);

    // Check if profile already exists by checking user mapping
    final existingProfileId = await _getUserProfileId(user.uid);
    if (existingProfileId != null) {
      throw const ProfileCreationException(
          'Profile already exists for this user');
    }

    try {
      // Generate a unique community profile ID
      final profileId = _firestore.collection('communityProfiles').doc().id;

      // Create the profile
      final now = DateTime.now();
      final profile = CommunityProfileEntity(
        id: profileId,
        displayName: displayName.trim(),
        gender: gender.toLowerCase(),
        avatarUrl: avatarUrl?.trim(),
        isAnonymous: isAnonymous,
        createdAt: now,
        updatedAt: now,
      );

      // Create profile and store user mapping atomically
      await _firestore.runTransaction((transaction) async {
        // Create the community profile
        await _repository.createProfile(profile);

        // Store user-to-profile mapping
        transaction.set(
          _firestore.collection('userProfileMappings').doc(user.uid),
          {
            'communityProfileId': profileId,
            'createdAt': FieldValue.serverTimestamp(),
            'isDeleted': false,
          },
        );
      });

      return profile;
    } catch (e) {
      if (e is CommunityException) {
        rethrow;
      }
      throw ProfileCreationException('Failed to create profile: $e');
    }
  }

  @override
  Future<CommunityProfileEntity?> getCurrentProfile() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AuthenticationException('User not authenticated');
    }

    // Get profile ID from mapping
    final profileId = await _getUserProfileId(user.uid);
    if (profileId == null) {
      return null;
    }

    return await _repository.getProfile(profileId);
  }

  @override
  Future<CommunityProfileEntity> updateProfile({
    String? displayName,
    String? gender,
    bool? isAnonymous,
    String? avatarUrl,
    bool? isPlusUser,
    bool? shareRelapseStreaks,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AuthenticationException('User not authenticated');
    }

    // Get profile ID from mapping
    final profileId = await _getUserProfileId(user.uid);
    if (profileId == null) {
      throw const ProfileNotFoundException('Profile not found for user');
    }

    // Get existing profile
    final existingProfile = await _repository.getProfile(profileId);
    if (existingProfile == null) {
      throw const ProfileNotFoundException('Profile not found for user');
    }

    // Validate new data if provided
    if (displayName != null) {
      _validateDisplayName(displayName);
    }
    if (gender != null) {
      _validateGender(gender);
    }

    // Create updated profile
    final updatedProfile = existingProfile.copyWith(
      displayName: displayName?.trim(),
      gender: gender?.toLowerCase(),
      isAnonymous: isAnonymous,
      avatarUrl: avatarUrl?.trim(),
      isPlusUser: isPlusUser,
      shareRelapseStreaks: shareRelapseStreaks,
      updatedAt: DateTime.now(),
    );

    try {
      await _repository.updateProfile(updatedProfile);
      return updatedProfile;
    } catch (e) {
      if (e is CommunityException) {
        rethrow;
      }
      throw ProfileUpdateException('Failed to update profile: $e');
    }
  }

  @override
  Future<bool> hasProfile() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AuthenticationException('User not authenticated');
    }

    final profileId = await _getUserProfileId(user.uid);
    return profileId != null;
  }

  @override
  Stream<CommunityProfileEntity?> watchProfile() {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AuthenticationException('User not authenticated');
    }

    return Stream.fromFuture(_getUserProfileId(user.uid))
        .asyncExpand((profileId) {
      if (profileId == null) {
        return Stream.value(null);
      }
      return _repository.watchProfile(profileId);
    });
  }

  @override
  Future<void> recordInterest() async {
    // Use local cache to avoid duplicate calls
    if (_hasRecordedInterest) {
      return;
    }

    final user = _auth.currentUser;
    if (user == null) {
      throw const AuthenticationException('User not authenticated');
    }

    try {
      await _repository.recordInterest();
      _hasRecordedInterest = true;
    } catch (e) {
      // Don't throw for interest recording failures
      // This is a nice-to-have feature, not critical
      print('Failed to record community interest: $e');
    }
  }

  /// Validates both display name and gender
  void _validateProfileData(String displayName, String gender) {
    _validateDisplayName(displayName);
    _validateGender(gender);
  }

  /// Validates display name
  void _validateDisplayName(String displayName) {
    final trimmed = displayName.trim();
    if (trimmed.isEmpty) {
      throw const ValidationException('Display name cannot be empty');
    }
    if (trimmed.length < 2) {
      throw const ValidationException(
          'Display name must be at least 2 characters');
    }
    if (trimmed.length > 50) {
      throw const ValidationException(
          'Display name cannot exceed 50 characters');
    }

    // Check for inappropriate content (basic filter)
    if (_containsInappropriateContent(trimmed)) {
      throw const ValidationException(
          'Display name contains inappropriate content');
    }
  }

  /// Validates gender
  void _validateGender(String gender) {
    final validGenders = ['male', 'female', 'other'];
    if (!validGenders.contains(gender.toLowerCase())) {
      throw const ValidationException('Gender must be male, female, or other');
    }
  }

  /// Basic content filter for inappropriate content
  bool _containsInappropriateContent(String text) {
    // This is a basic implementation - in production, you'd want a more sophisticated filter
    final inappropriateWords = ['admin', 'moderator', 'support', 'official'];
    final lowerText = text.toLowerCase();

    return inappropriateWords.any((word) => lowerText.contains(word));
  }

  /// Gets the community profile ID for a user
  Future<String?> _getUserProfileId(String userId) async {
    try {
      final doc =
          await _firestore.collection('userProfileMappings').doc(userId).get();

      if (!doc.exists || doc.data() == null) {
        return null;
      }

      final data = doc.data()!;
      final isDeleted = data['isDeleted'] as bool? ?? false;

      if (isDeleted) {
        return null;
      }

      return data['communityProfileId'] as String?;
    } catch (e) {
      return null;
    }
  }

  @override
  Stream<DeletionProgress> deleteProfile() {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AuthenticationException('User not authenticated');
    }

    return _performDeletion(user.uid);
  }

  @override
  Future<String?> getDeletedProfileId() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AuthenticationException('User not authenticated');
    }

    try {
      final doc = await _firestore
          .collection('userProfileMappings')
          .doc(user.uid)
          .get();

      if (!doc.exists || doc.data() == null) {
        return null;
      }

      final data = doc.data()!;
      final isDeleted = data['isDeleted'] as bool? ?? false;

      if (isDeleted) {
        return data['communityProfileId'] as String?;
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<CommunityProfileEntity> restoreProfile(String deletedProfileId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AuthenticationException('User not authenticated');
    }

    try {
      // Check if the deleted profile exists
      final profileDoc = await _firestore
          .collection('communityProfiles')
          .doc(deletedProfileId)
          .get();

      if (!profileDoc.exists) {
        throw const ProfileNotFoundException('Deleted profile not found');
      }

      // Restore the profile atomically
      await _firestore.runTransaction((transaction) async {
        // Reactivate profile
        transaction.update(
          _firestore.collection('communityProfiles').doc(deletedProfileId),
          {
            'isDeleted': false,
            'deletedAt': null,
            'restoredAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          },
        );

        // Update user mapping
        transaction.update(
          _firestore.collection('userProfileMappings').doc(user.uid),
          {
            'isDeleted': false,
            'restoredAt': FieldValue.serverTimestamp(),
          },
        );
      });

      // Return the restored profile
      final restoredProfile = await _repository.getProfile(deletedProfileId);
      if (restoredProfile == null) {
        throw const ProfileNotFoundException('Failed to load restored profile');
      }

      return restoredProfile;
    } catch (e) {
      if (e is CommunityException) {
        rethrow;
      }
      throw ProfileUpdateException('Failed to restore profile: $e');
    }
  }

  /// Performs the actual deletion process with progress tracking
  Stream<DeletionProgress> _performDeletion(String userId) async* {
    try {
      // Get profile ID
      final profileId = await _getUserProfileId(userId);
      if (profileId == null) {
        throw const ProfileNotFoundException('Profile not found for deletion');
      }

      // Step 1: Delete posts
      yield DeletionProgress(
        step: DeletionStep.deletingPosts,
        completedItems: 0,
        totalItems: 0,
        message: 'Counting posts...',
      );

      await _deleteUserPosts(profileId);

      // Step 2: Delete comments
      yield DeletionProgress(
        step: DeletionStep.deletingComments,
        completedItems: 0,
        totalItems: 0,
        message: 'Counting comments...',
      );

      await _deleteUserComments(profileId);

      // Step 3: Delete interactions
      yield DeletionProgress(
        step: DeletionStep.deletingInteractions,
        completedItems: 0,
        totalItems: 0,
        message: 'Counting interactions...',
      );

      await _deleteUserInteractions(profileId);

      // Step 4: Remove profile data
      yield DeletionProgress(
        step: DeletionStep.removingProfileData,
        completedItems: 0,
        totalItems: 1,
        message: 'Removing profile data...',
      );

      await _deleteProfileData(profileId);

      yield DeletionProgress(
        step: DeletionStep.removingProfileData,
        completedItems: 1,
        totalItems: 1,
        message: 'Profile data removed',
      );

      // Step 5: Clean up mappings
      yield DeletionProgress(
        step: DeletionStep.cleaningUpMappings,
        completedItems: 0,
        totalItems: 1,
        message: 'Cleaning up mappings...',
      );

      await _updateUserMapping(userId, profileId, isDeleted: true);

      yield DeletionProgress(
        step: DeletionStep.cleaningUpMappings,
        completedItems: 1,
        totalItems: 1,
        message: 'Deletion completed',
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Deletes all posts created by the user
  Future<void> _deleteUserPosts(String profileId) async {
    final postsCollection = _firestore.collection('posts');

    Query query = postsCollection
        .where('authorCPId', isEqualTo: profileId)
        .where('isDeleted', isEqualTo: false)
        .limit(500);

    while (true) {
      final snapshot = await query.get();
      if (snapshot.docs.isEmpty) break;

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {
          'isDeleted': true,
          'deletedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      // Set up next query
      if (snapshot.docs.length == 500) {
        query = query.startAfterDocument(snapshot.docs.last);
      } else {
        break;
      }
    }
  }

  /// Deletes all comments created by the user
  Future<void> _deleteUserComments(String profileId) async {
    final commentsCollection = _firestore.collection('comments');

    Query query = commentsCollection
        .where('authorCPId', isEqualTo: profileId)
        .where('isDeleted', isEqualTo: false)
        .limit(500);

    while (true) {
      final snapshot = await query.get();
      if (snapshot.docs.isEmpty) break;

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {
          'isDeleted': true,
          'deletedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      // Set up next query
      if (snapshot.docs.length == 500) {
        query = query.startAfterDocument(snapshot.docs.last);
      } else {
        break;
      }
    }
  }

  /// Deletes all interactions (likes) created by the user
  Future<void> _deleteUserInteractions(String profileId) async {
    final likesCollection = _firestore.collection('likes');

    Query query =
        likesCollection.where('userCPId', isEqualTo: profileId).limit(500);

    while (true) {
      final snapshot = await query.get();
      if (snapshot.docs.isEmpty) break;

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      // Set up next query
      if (snapshot.docs.length == 500) {
        query = query.startAfterDocument(snapshot.docs.last);
      } else {
        break;
      }
    }
  }

  /// Marks the profile as deleted
  Future<void> _deleteProfileData(String profileId) async {
    await _firestore.collection('communityProfiles').doc(profileId).update({
      'isDeleted': true,
      'deletedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Updates the user mapping
  Future<void> _updateUserMapping(String userId, String profileId,
      {required bool isDeleted}) async {
    await _firestore.collection('userProfileMappings').doc(userId).update({
      'isDeleted': isDeleted,
      if (isDeleted) 'deletedAt': FieldValue.serverTimestamp(),
    });
  }
}
