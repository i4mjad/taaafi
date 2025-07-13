import '../entities/community_profile_entity.dart';

/// Abstract service for community-related operations
///
/// This service defines the contract for community profile management
/// and handles referral code processing.
abstract class CommunityService {
  /// Creates a new community profile
  ///
  /// Validates the input data and creates a profile for the authenticated user.
  /// Throws [ValidationException] if the input data is invalid.
  /// Throws [AuthenticationException] if the user is not authenticated.
  Future<CommunityProfileEntity> createProfile({
    required String displayName,
    required String gender,
    required bool isAnonymous,
    String? avatarUrl,
  });

  /// Gets the current user's community profile
  ///
  /// Returns null if the user doesn't have a profile.
  /// Throws [AuthenticationException] if the user is not authenticated.
  Future<CommunityProfileEntity?> getCurrentProfile();

  /// Updates the current user's community profile
  ///
  /// Throws [ValidationException] if the input data is invalid.
  /// Throws [AuthenticationException] if the user is not authenticated.
  Future<CommunityProfileEntity> updateProfile({
    String? displayName,
    String? gender,
    bool? isAnonymous,
    String? avatarUrl,
  });

  /// Checks if the current user has a community profile
  ///
  /// Throws [AuthenticationException] if the user is not authenticated.
  Future<bool> hasProfile();

  /// Watches the current user's community profile
  ///
  /// Returns a stream that emits the profile whenever it changes.
  /// Throws [AuthenticationException] if the user is not authenticated.
  Stream<CommunityProfileEntity?> watchProfile();

  /// Records user interest in community features
  ///
  /// This is used for analytics and feature adoption tracking.
  Future<void> recordInterest();
}
