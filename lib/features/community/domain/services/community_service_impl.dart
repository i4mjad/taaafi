import 'package:firebase_auth/firebase_auth.dart';
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

  /// Cache for interest recording to avoid duplicate calls
  bool _hasRecordedInterest = false;

  CommunityServiceImpl(this._repository, this._auth);

  @override
  Future<CommunityProfileEntity> createProfile({
    required String displayName,
    required String gender,
    required bool postAnonymouslyByDefault,
    String? avatarUrl,
  }) async {
    // Check authentication
    final user = _auth.currentUser;
    if (user == null) {
      throw const AuthenticationException('User not authenticated');
    }

    // Validate input data
    _validateProfileData(displayName, gender);

    // Check if profile already exists
    final existingProfile = await _repository.getProfile(user.uid);
    if (existingProfile != null) {
      throw const ProfileCreationException(
          'Profile already exists for this user');
    }

    try {
      // Create the profile
      final now = DateTime.now();
      final profile = CommunityProfileEntity(
        id: user.uid,
        displayName: displayName.trim(),
        gender: gender.toLowerCase(),
        avatarUrl: avatarUrl?.trim(),
        postAnonymouslyByDefault: postAnonymouslyByDefault,
        createdAt: now,
        updatedAt: now,
      );

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

    return await _repository.getProfile(user.uid);
  }

  @override
  Future<CommunityProfileEntity> updateProfile({
    String? displayName,
    String? gender,
    bool? postAnonymouslyByDefault,
    String? avatarUrl,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AuthenticationException('User not authenticated');
    }

    // Get existing profile
    final existingProfile = await _repository.getProfile(user.uid);
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
      postAnonymouslyByDefault: postAnonymouslyByDefault,
      avatarUrl: avatarUrl?.trim(),
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

    return await _repository.profileExists(user.uid);
  }

  @override
  Stream<CommunityProfileEntity?> watchProfile() {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AuthenticationException('User not authenticated');
    }

    return _repository.watchProfile(user.uid);
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
}
