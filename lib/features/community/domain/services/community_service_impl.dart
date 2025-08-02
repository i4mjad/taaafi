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
    bool? isPlusUser,
  }) async {
    // Check authentication
    final user = _auth.currentUser;
    if (user == null) {
      throw const AuthenticationException('User not authenticated');
    }

    // Validate input data
    _validateProfileData(displayName, gender);

    // Check if user already has an active profile
    final existingProfile = await _getCurrentProfileByUserUID(user.uid);
    if (existingProfile != null) {
      throw const ProfileCreationException(
          'User already has an active community profile');
    }

    try {
      // Generate a unique community profile ID
      final profileId = _firestore.collection('communityProfiles').doc().id;

      // Create the profile
      final now = DateTime.now();
      final profile = CommunityProfileEntity(
        id: profileId,
        userUID: user.uid, // Store user UID for reference and queries
        displayName: displayName.trim(),
        gender: gender.toLowerCase(),
        avatarUrl: avatarUrl?.trim(),
        isAnonymous: isAnonymous,
        isPlusUser:
            isPlusUser ?? false, // Use provided value or default to false
        createdAt: now,
        updatedAt: now,
      );

      // Create the community profile
      await _repository.createProfile(profile);

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

    return _getCurrentProfileByUserUID(user.uid);
  }

  @override
  Future<CommunityProfileEntity> updateProfile({
    String? displayName,
    String? gender,
    String? avatarUrl,
    bool? isAnonymous,
    bool? isPlusUser,
    bool? shareRelapseStreaks,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AuthenticationException('User not authenticated');
    }

    final currentProfile = await _getCurrentProfileByUserUID(user.uid);
    if (currentProfile == null) {
      throw const ProfileNotFoundException('User has no community profile');
    }

    try {
      final updatedProfile = currentProfile.copyWith(
        displayName: displayName ?? currentProfile.displayName,
        gender: gender ?? currentProfile.gender,
        avatarUrl: avatarUrl ?? currentProfile.avatarUrl,
        isAnonymous: isAnonymous ?? currentProfile.isAnonymous,
        isPlusUser: isPlusUser ?? currentProfile.isPlusUser,
        shareRelapseStreaks:
            shareRelapseStreaks ?? currentProfile.shareRelapseStreaks,
        updatedAt: DateTime.now(),
      );

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

    final profile = await _getCurrentProfileByUserUID(user.uid);
    return profile != null;
  }

  @override
  Stream<CommunityProfileEntity?> watchProfile() {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AuthenticationException('User not authenticated');
    }

    return _firestore
        .collection('communityProfiles')
        .where('userUID', isEqualTo: user.uid)
        .where('isDeleted', isNotEqualTo: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return null;
      }

      final doc = snapshot.docs.first;
      final data = doc.data();

      // Double-check that the profile is not deleted (for safety)
      if (data['isDeleted'] == true) {
        return null;
      }

      return CommunityProfileEntity.fromJson({
        'id': doc.id,
        ...data,
      });
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

  /// Helper method to get current user's profile by userUID
  Future<CommunityProfileEntity?> _getCurrentProfileByUserUID(
      String userUID) async {
    try {
      final snapshot = await _firestore
          .collection('communityProfiles')
          .where('userUID', isEqualTo: userUID)
          .where('isDeleted', isNotEqualTo: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      final doc = snapshot.docs.first;
      final data = doc.data();

      // Double-check that the profile is not deleted (for safety)
      if (data['isDeleted'] == true) {
        return null;
      }

      return CommunityProfileEntity.fromJson({
        'id': doc.id,
        ...data,
      });
    } catch (e) {
      print('Error getting profile for user $userUID: $e');
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
      final snapshot = await _firestore
          .collection('communityProfiles')
          .where('userUID', isEqualTo: user.uid)
          .where('isDeleted', isEqualTo: true)
          .orderBy('createdAt',
              descending: true) // Get the latest created deleted profile
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      final doc = snapshot.docs.first;
      return doc.id; // Return the document ID which is the community profile ID
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
      // Check if the deleted profile exists and belongs to the current user
      final profileDoc = await _firestore
          .collection('communityProfiles')
          .doc(deletedProfileId)
          .get();

      if (!profileDoc.exists) {
        throw const ProfileNotFoundException('Deleted profile not found');
      }

      final profileData = profileDoc.data();
      if (profileData == null) {
        throw const ProfileNotFoundException('Invalid profile data');
      }

      // Validate that the profile belongs to the current user
      if (profileData['userUID'] != user.uid) {
        throw const ProfileNotFoundException(
            'Profile does not belong to current user');
      }

      // Validate that the profile is actually deleted
      if (profileData['isDeleted'] != true) {
        throw const ProfileUpdateException('Profile is not deleted');
      }

      // Validate that this is the latest deleted profile for the user
      final latestDeletedProfileId = await getDeletedProfileId();
      if (latestDeletedProfileId != deletedProfileId) {
        throw const ProfileUpdateException(
            'Only the latest deleted profile can be restored');
      }

      // Restore the profile atomically
      await _firestore.runTransaction((transaction) async {
        // Simply reactivate profile
        transaction.update(
          _firestore.collection('communityProfiles').doc(deletedProfileId),
          {
            'isDeleted': false,
            'deletedAt': null,
            'restoredAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
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
      // Get user's profile
      final profile = await _getCurrentProfileByUserUID(userId);
      if (profile == null) {
        throw const ProfileNotFoundException('Profile not found for deletion');
      }

      final profileId = profile.id;

      // Step 1: Mark profile as deleted
      yield DeletionProgress(
        step: DeletionStep.markingProfileDeleted,
        completedItems: 0,
        totalItems: 1,
        message: 'Marking profile as deleted...',
      );

      await _deleteProfileData(profileId);

      yield DeletionProgress(
        step: DeletionStep.markingProfileDeleted,
        completedItems: 1,
        totalItems: 1,
        message: 'Profile marked as deleted',
      );

      // Step 2: Complete
      yield DeletionProgress(
        step: DeletionStep.completed,
        completedItems: 1,
        totalItems: 1,
        message: 'Deletion completed',
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Marks the profile as deleted
  Future<void> _deleteProfileData(String profileId) async {
    await _firestore.collection('communityProfiles').doc(profileId).update({
      'isDeleted': true,
      'deletedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
