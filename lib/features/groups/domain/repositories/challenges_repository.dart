import '../entities/challenge_entity.dart';
import '../entities/challenge_participation_entity.dart';
import '../entities/challenge_stats_entity.dart';
import '../entities/challenge_update_entity.dart';

/// Repository interface for challenge operations
///
/// Defines the contract for challenge data access
abstract class ChallengesRepository {
  // ============================================
  // Challenge CRUD Operations
  // ============================================

  /// Create a new challenge
  ///
  /// Returns the ID of the created challenge
  Future<String> createChallenge(ChallengeEntity challenge);

  /// Get a challenge by ID
  Future<ChallengeEntity?> getChallengeById(String challengeId);

  /// Update an existing challenge
  Future<void> updateChallenge(ChallengeEntity challenge);

  /// Delete a challenge
  Future<void> deleteChallenge(String challengeId);

  // ============================================
  // Challenge Queries
  // ============================================

  /// Get all challenges for a group
  Future<List<ChallengeEntity>> getGroupChallenges(String groupId);

  /// Get active challenges for a group
  Future<List<ChallengeEntity>> getActiveChallenges(String groupId);

  /// Get completed challenges for a group
  Future<List<ChallengeEntity>> getCompletedChallenges(String groupId);

  /// Get upcoming (draft) challenges for a group
  Future<List<ChallengeEntity>> getUpcomingChallenges(String groupId);

  // ============================================
  // Participation Operations
  // ============================================

  /// Join a challenge
  ///
  /// Creates a participation record for the user
  Future<String> joinChallenge({
    required String challengeId,
    required String cpId,
    required String groupId,
    required int goalValue,
  });

  /// Leave a challenge
  ///
  /// Updates participation status to 'quit'
  Future<void> leaveChallenge({
    required String challengeId,
    required String cpId,
  });

  /// Get user's participation in a challenge
  Future<ChallengeParticipationEntity?> getParticipation({
    required String challengeId,
    required String cpId,
  });

  /// Get all participants for a challenge
  Future<List<ChallengeParticipationEntity>> getChallengeParticipants(
    String challengeId,
  );

  /// Get active participants only
  Future<List<ChallengeParticipationEntity>> getActiveParticipants(
    String challengeId,
  );

  /// Get user's active challenges
  Future<List<ChallengeParticipationEntity>> getUserActiveChallenges(
    String cpId,
  );

  // ============================================
  // Progress Operations
  // ============================================

  /// Update progress for a participant
  Future<void> updateProgress({
    required String challengeId,
    required String cpId,
    required int newCurrentValue,
    required int newProgress,
  });

  /// Record daily activity for streak tracking
  Future<void> recordDailyActivity({
    required String challengeId,
    required String cpId,
  });

  /// Mark participation as completed
  Future<void> completeParticipation({
    required String challengeId,
    required String cpId,
  });

  // ============================================
  // Leaderboard & Rankings
  // ============================================

  /// Get leaderboard for a challenge
  ///
  /// Returns participants sorted by progress (descending)
  Future<List<ChallengeParticipationEntity>> getLeaderboard({
    required String challengeId,
    int limit = 10,
  });

  /// Update rankings for all participants
  ///
  /// Recalculates and updates rank field for all participants
  Future<void> updateRankings(String challengeId);

  // ============================================
  // Statistics
  // ============================================

  /// Get statistics for a challenge
  Future<ChallengeStatsEntity> getChallengeStats(String challengeId);

  /// Get participant count for a challenge
  Future<int> getParticipantCount(String challengeId);

  /// Get average progress for a challenge
  Future<double> getAverageProgress(String challengeId);

  // ============================================
  // Challenge Updates/Feed
  // ============================================

  /// Create a challenge update (progress, milestone, completion)
  Future<String> createChallengeUpdate(ChallengeUpdateEntity update);

  /// Get recent updates for a challenge
  Future<List<ChallengeUpdateEntity>> getChallengeUpdates({
    required String challengeId,
    int limit = 20,
  });

  // ============================================
  // Challenge Management
  // ============================================

  /// Increment participant count
  Future<void> incrementParticipantCount(String challengeId);

  /// Decrement participant count
  Future<void> decrementParticipantCount(String challengeId);

  /// Add participant to challenge participants array
  Future<void> addParticipantToChallenge({
    required String challengeId,
    required String cpId,
  });

  /// Remove participant from challenge participants array
  Future<void> removeParticipantFromChallenge({
    required String challengeId,
    required String cpId,
  });
}

