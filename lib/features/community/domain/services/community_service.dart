import '../entities/community_profile_entity.dart';
import '../entities/profile_statistics.dart';

/// Enum for deletion progress steps
enum DeletionStep {
  markingProfileDeleted,
  completed,
}

/// Progress information for community profile deletion
class DeletionProgress {
  final DeletionStep step;
  final int completedItems;
  final int totalItems;
  final String message;

  const DeletionProgress({
    required this.step,
    required this.completedItems,
    required this.totalItems,
    required this.message,
  });

  double get percentage => totalItems > 0 ? completedItems / totalItems : 0;
}

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
    bool? isPlusUser,
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
    bool? isPlusUser,
    bool? shareRelapseStreaks,
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

  /// Deletes the current user's community profile and all associated data
  ///
  /// This includes posts, comments, interactions, and profile data.
  /// The deletion progress is streamed to allow UI updates.
  /// Throws [AuthenticationException] if the user is not authenticated.
  Stream<DeletionProgress> deleteProfile();

  /// Checks if the current user has a deleted profile that can be restored
  ///
  /// Returns the deleted profile ID if one exists, null otherwise.
  /// Throws [AuthenticationException] if the user is not authenticated.
  Future<String?> getDeletedProfileId();

  /// Gets all deleted profiles for the current user (Plus feature)
  ///
  /// Returns a list of all deleted profiles ordered by deletion date (newest first).
  /// Throws [AuthenticationException] if the user is not authenticated.
  Future<List<CommunityProfileEntity>> getAllDeletedProfiles();

  /// Gets profile statistics for a specific profile
  ///
  /// Returns statistics like post count, comment count, etc.
  /// Throws [AuthenticationException] if the user is not authenticated.
  Future<ProfileStatistics> getProfileStatistics(String profileId);

  /// Restores a previously deleted community profile
  ///
  /// Reactivates the profile and makes it visible again.
  /// [bypassLatestCheck] allows Plus users to restore any profile, not just the latest.
  /// Throws [AuthenticationException] if the user is not authenticated.
  /// Throws [ProfileNotFoundException] if no deleted profile exists.
  Future<CommunityProfileEntity> restoreProfile(
    String deletedProfileId, {
    bool bypassLatestCheck = false,
  });
}
