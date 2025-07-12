import '../entities/community_profile_entity.dart';

/// Repository interface for community-related data operations
///
/// This interface defines the contract for data access operations related to
/// community profiles. It follows the repository pattern to abstract data
/// persistence details from the domain layer.
abstract class CommunityRepository {
  /// Creates a new community profile
  ///
  /// Throws [ProfileCreationException] if profile creation fails
  /// Throws [NetworkException] if network operation fails
  Future<void> createProfile(CommunityProfileEntity profile);

  /// Retrieves a community profile by user ID
  ///
  /// Returns null if the profile doesn't exist
  /// Throws [NetworkException] if network operation fails
  Future<CommunityProfileEntity?> getProfile(String uid);

  /// Updates an existing community profile
  ///
  /// Throws [ProfileUpdateException] if profile update fails
  /// Throws [NetworkException] if network operation fails
  Future<void> updateProfile(CommunityProfileEntity profile);

  /// Deletes a community profile
  ///
  /// Throws [ProfileDeletionException] if profile deletion fails
  /// Throws [NetworkException] if network operation fails
  Future<void> deleteProfile(String uid);

  /// Checks if a profile exists for the given user ID
  ///
  /// Throws [NetworkException] if network operation fails
  Future<bool> profileExists(String uid);

  /// Watches a community profile for real-time updates
  ///
  /// Returns a stream that emits profile changes
  /// Throws [NetworkException] if network operation fails
  Stream<CommunityProfileEntity?> watchProfile(String uid);

  /// Records user interest in community features
  ///
  /// This is used for analytics and feature adoption tracking
  /// Throws [NetworkException] if network operation fails
  Future<void> recordInterest();
}
