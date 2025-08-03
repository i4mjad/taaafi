import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../entities/community_profile_entity.dart';
import '../entities/profile_statistics.dart';
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
    print('🔄 GetDeletedProfileId: Starting...');

    final user = _auth.currentUser;
    if (user == null) {
      print('❌ GetDeletedProfileId: User not authenticated');
      throw const AuthenticationException('User not authenticated');
    }

    print('✅ GetDeletedProfileId: User authenticated: ${user.uid}');

    try {
      print(
          '🔄 GetDeletedProfileId: Querying Firestore for deleted profiles...');

      // First try with orderBy (might fail due to indexing)
      QuerySnapshot<Map<String, dynamic>>? snapshot;

      try {
        print('🔄 GetDeletedProfileId: Trying query with orderBy...');
        snapshot = await _firestore
            .collection('communityProfiles')
            .where('userUID', isEqualTo: user.uid)
            .where('isDeleted', isEqualTo: true)
            .orderBy('deletedAt',
                descending: true) // Changed to deletedAt for consistency
            .limit(1)
            .get();
        print('✅ GetDeletedProfileId: Query with orderBy succeeded');
      } catch (orderByError) {
        print(
            '⚠️ GetDeletedProfileId: OrderBy failed, trying without orderBy: $orderByError');

        // Fallback: get all deleted profiles and sort manually
        snapshot = await _firestore
            .collection('communityProfiles')
            .where('userUID', isEqualTo: user.uid)
            .where('isDeleted', isEqualTo: true)
            .get();
        print('✅ GetDeletedProfileId: Query without orderBy succeeded');
      }

      print(
          '🔄 GetDeletedProfileId: Query completed. Found ${snapshot.docs.length} documents');

      if (snapshot.docs.isEmpty) {
        print('❌ GetDeletedProfileId: No deleted profiles found');
        return null;
      }

      // If we have multiple docs (fallback case), sort them manually
      QueryDocumentSnapshot<Map<String, dynamic>> doc;
      if (snapshot.docs.length == 1) {
        doc = snapshot.docs.first;
        print('✅ GetDeletedProfileId: Using single document found');
      } else {
        print(
            '🔄 GetDeletedProfileId: Multiple documents found (${snapshot.docs.length}), sorting manually...');

        // Sort by deletedAt descending to get the most recently deleted
        final sortedDocs = snapshot.docs.toList();
        sortedDocs.sort((a, b) {
          final aDeletedAt = a.data()['deletedAt'] as Timestamp?;
          final bDeletedAt = b.data()['deletedAt'] as Timestamp?;

          // Handle null values (put them at the end)
          if (aDeletedAt == null && bDeletedAt == null) return 0;
          if (aDeletedAt == null) return 1;
          if (bDeletedAt == null) return -1;

          return bDeletedAt.compareTo(aDeletedAt); // Descending order
        });

        doc = sortedDocs.first;
        print('✅ GetDeletedProfileId: Using most recently deleted document');
      }

      final docData = doc.data();

      print('✅ GetDeletedProfileId: Found deleted profile document');
      print('✅ GetDeletedProfileId: Document ID: ${doc.id}');
      print(
          '✅ GetDeletedProfileId: Document data keys: ${docData.keys.toList()}');
      print('✅ GetDeletedProfileId: isDeleted: ${docData['isDeleted']}');
      print('✅ GetDeletedProfileId: userUID: ${docData['userUID']}');
      print('✅ GetDeletedProfileId: displayName: ${docData['displayName']}');
      print('✅ GetDeletedProfileId: deletedAt: ${docData['deletedAt']}');

      print('✅ GetDeletedProfileId: Returning profile ID: ${doc.id}');
      return doc.id; // Return the document ID which is the community profile ID
    } catch (e, stackTrace) {
      print('❌ GetDeletedProfileId: Exception occurred: $e');
      print('❌ GetDeletedProfileId: Stack trace: $stackTrace');
      return null;
    }
  }

  @override
  Future<List<CommunityProfileEntity>> getAllDeletedProfiles() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AuthenticationException('User not authenticated');
    }

    try {
      final snapshot = await _firestore
          .collection('communityProfiles')
          .where('userUID', isEqualTo: user.uid)
          .where('isDeleted', isEqualTo: true)
          .orderBy('deletedAt', descending: true) // Most recently deleted first
          .get();

      return snapshot.docs
          .map((doc) => CommunityProfileEntity.fromJson({
                'id': doc.id,
                ...doc.data(),
              }))
          .toList();
    } catch (e) {
      print('Error getting all deleted profiles: $e');
      return [];
    }
  }

  @override
  Future<ProfileStatistics> getProfileStatistics(String profileId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AuthenticationException('User not authenticated');
    }

    try {
      // Get profile data first to get creation/deletion dates
      final profileDoc =
          await _firestore.collection('communityProfiles').doc(profileId).get();

      if (!profileDoc.exists) {
        throw const ProfileNotFoundException('Profile not found');
      }

      final profileData = profileDoc.data()!;
      final createdAt = (profileData['createdAt'] as Timestamp).toDate();
      final deletedAt = profileData['deletedAt'] != null
          ? (profileData['deletedAt'] as Timestamp).toDate()
          : null;

      // Calculate active days
      final endDate = deletedAt ?? DateTime.now();
      final activeDays = endDate.difference(createdAt).inDays;

      // Count posts
      final postsSnapshot = await _firestore
          .collection('forumPosts')
          .where('authorCPId', isEqualTo: profileId)
          .get();

      // Count comments
      final commentsSnapshot = await _firestore
          .collection('comments')
          .where('authorCPId', isEqualTo: profileId)
          .get();

      // Count interactions given by this profile
      final interactionsSnapshot = await _firestore
          .collection('interactions')
          .where('userCPId', isEqualTo: profileId)
          .get();

      // Count interactions received on this profile's content
      final receivedInteractionsSnapshot = await _firestore
          .collection('interactions')
          .where('targetAuthorCPId', isEqualTo: profileId)
          .get();

      return ProfileStatistics(
        postCount: postsSnapshot.docs.length,
        commentCount: commentsSnapshot.docs.length,
        interactionCount: interactionsSnapshot.docs.length,
        receivedInteractionCount: receivedInteractionsSnapshot.docs.length,
        deletedAt: deletedAt,
        activeDays: activeDays,
      );
    } catch (e) {
      print('Error getting profile statistics: $e');
      return const ProfileStatistics(
        postCount: 0,
        commentCount: 0,
        interactionCount: 0,
        receivedInteractionCount: 0,
        activeDays: 0,
      );
    }
  }

  @override
  Future<CommunityProfileEntity> restoreProfile(
    String deletedProfileId, {
    bool bypassLatestCheck = false,
  }) async {
    print('🔄 RestoreService: Starting profile restoration...');
    print('🔄 RestoreService: Profile ID: $deletedProfileId');
    print('🔄 RestoreService: Bypass latest check: $bypassLatestCheck');

    final user = _auth.currentUser;
    if (user == null) {
      print('❌ RestoreService: User not authenticated');
      throw const AuthenticationException('User not authenticated');
    }

    print('✅ RestoreService: User authenticated: ${user.uid}');

    try {
      print('🔄 RestoreService: Checking if deleted profile exists...');
      // Check if the deleted profile exists and belongs to the current user
      final profileDoc = await _firestore
          .collection('communityProfiles')
          .doc(deletedProfileId)
          .get();

      if (!profileDoc.exists) {
        print('❌ RestoreService: Profile document does not exist');
        throw const ProfileNotFoundException('Deleted profile not found');
      }

      print('✅ RestoreService: Profile document exists');

      final profileData = profileDoc.data();
      if (profileData == null) {
        print('❌ RestoreService: Profile data is null');
        throw const ProfileNotFoundException('Invalid profile data');
      }

      print(
          '✅ RestoreService: Profile data loaded: ${profileData.keys.toList()}');

      // Validate that the profile belongs to the current user
      final profileUserUID = profileData['userUID'];
      print(
          '🔄 RestoreService: Profile userUID: $profileUserUID, Current user UID: ${user.uid}');

      if (profileUserUID != user.uid) {
        print('❌ RestoreService: Profile belongs to different user');
        throw const ProfileNotFoundException(
            'Profile does not belong to current user');
      }

      print('✅ RestoreService: Profile ownership validated');

      // Check if user already has an active profile - PREVENT MULTIPLE ACTIVE PROFILES
      print('🔄 RestoreService: Checking for existing active profiles...');
      final existingActiveProfile = await _getCurrentProfileByUserUID(user.uid);
      if (existingActiveProfile != null) {
        print(
            '❌ RestoreService: User already has an active profile: ${existingActiveProfile.id}');
        throw const ProfileUpdateException(
            'Cannot restore profile: User already has an active community profile');
      }
      print('✅ RestoreService: No existing active profiles found');

      // Validate that the profile is actually deleted
      final isDeleted = profileData['isDeleted'];
      print('🔄 RestoreService: Profile isDeleted: $isDeleted');

      if (isDeleted != true) {
        print('❌ RestoreService: Profile is not marked as deleted');
        throw const ProfileUpdateException('Profile is not deleted');
      }

      print('✅ RestoreService: Profile is marked as deleted');

      // Validate that this is the latest deleted profile for the user (unless bypassed for Plus users)
      if (!bypassLatestCheck) {
        print(
            '🔄 RestoreService: Checking if this is the latest deleted profile...');
        final latestDeletedProfileId = await getDeletedProfileId();
        print(
            '🔄 RestoreService: Latest deleted profile ID: $latestDeletedProfileId');

        if (latestDeletedProfileId != deletedProfileId) {
          print('❌ RestoreService: Not the latest deleted profile');
          throw const ProfileUpdateException(
              'Only the latest deleted profile can be restored');
        }

        print('✅ RestoreService: This is the latest deleted profile');
      } else {
        print('✅ RestoreService: Latest check bypassed (Plus user)');
      }

      print('🔄 RestoreService: Starting Firestore transaction...');
      // Restore the profile atomically
      await _firestore.runTransaction((transaction) async {
        print('🔄 RestoreService: Inside transaction, updating profile...');
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

        print('✅ RestoreService: Transaction update completed');
      });

      print('✅ RestoreService: Firestore transaction completed successfully');

      print('🔄 RestoreService: Loading restored profile from repository...');
      // Return the restored profile
      final restoredProfile = await _repository.getProfile(deletedProfileId);
      if (restoredProfile == null) {
        print(
            '❌ RestoreService: Failed to load restored profile from repository');
        throw const ProfileNotFoundException('Failed to load restored profile');
      }

      print('✅ RestoreService: Profile restoration completed successfully!');
      print(
          '✅ RestoreService: Restored profile: ${restoredProfile.displayName} (${restoredProfile.id})');

      return restoredProfile;
    } catch (e, stackTrace) {
      print('❌ RestoreService: Exception occurred: $e');
      print('❌ RestoreService: Stack trace: $stackTrace');

      if (e is CommunityException) {
        print('❌ RestoreService: Rethrowing CommunityException');
        rethrow;
      }

      print('❌ RestoreService: Throwing ProfileUpdateException');
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
