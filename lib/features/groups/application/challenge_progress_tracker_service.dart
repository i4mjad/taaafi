import 'dart:developer';
import '../domain/entities/challenge_entity.dart';
import '../domain/repositories/challenges_repository.dart';

/// Service for automatically tracking challenge progress based on user activities
///
/// This service listens to user activities and updates challenge progress accordingly
class ChallengeProgressTrackerService {
  final ChallengesRepository _repository;

  const ChallengeProgressTrackerService(this._repository);

  /// Track when a user sends a message
  ///
  /// Updates progress for challenges with goalType = 'messages'
  Future<void> trackMessageSent({
    required String cpId,
    required String groupId,
  }) async {
    try {
      // Get user's active challenges
      final participations = await _repository.getUserActiveChallenges(cpId);

      for (final participation in participations) {
        // Get the challenge details
        final challenge =
            await _repository.getChallengeById(participation.challengeId);

        if (challenge == null) continue;
        if (challenge.groupId != groupId) continue;

        // Only update for message-based challenges
        if (challenge.goalType == GoalType.messages) {
          final newValue = participation.currentValue + 1;
          final newProgress =
              ((newValue / participation.goalValue) * 100).round();

          await _repository.updateProgress(
            challengeId: participation.challengeId,
            cpId: cpId,
            newCurrentValue: newValue,
            newProgress: newProgress,
          );

          // Auto-complete if reached goal
          if (newProgress >= 100) {
            await _repository.completeParticipation(
              challengeId: participation.challengeId,
              cpId: cpId,
            );
          }
        }
      }
    } catch (e, stackTrace) {
      log('Error in trackMessageSent: $e', stackTrace: stackTrace);
    }
  }

  /// Track daily activity
  ///
  /// Updates progress for challenges with goalType = 'daysActive'
  Future<void> trackDailyActivity({
    required String cpId,
  }) async {
    try {
      // Get user's active challenges
      final participations = await _repository.getUserActiveChallenges(cpId);

      for (final participation in participations) {
        // Get the challenge details
        final challenge =
            await _repository.getChallengeById(participation.challengeId);

        if (challenge == null) continue;

        // Only update for days-active challenges
        if (challenge.goalType == GoalType.daysActive ||
            challenge.type == ChallengeType.duration) {
          // Check if already updated today
          if (!participation.hasUpdatedToday()) {
            // Record daily activity
            await _repository.recordDailyActivity(
              challengeId: participation.challengeId,
              cpId: cpId,
            );

            // Update progress
            final newValue = participation.dailyLog.length + 1;
            final newProgress =
                ((newValue / participation.goalValue) * 100).round();

            await _repository.updateProgress(
              challengeId: participation.challengeId,
              cpId: cpId,
              newCurrentValue: newValue,
              newProgress: newProgress,
            );

            // Auto-complete if reached goal
            if (newProgress >= 100) {
              await _repository.completeParticipation(
                challengeId: participation.challengeId,
                cpId: cpId,
              );
            }
          }
        }
      }
    } catch (e, stackTrace) {
      log('Error in trackDailyActivity: $e', stackTrace: stackTrace);
    }
  }

  /// Check for challenge completions and failures (background job)
  ///
  /// Should be called daily by a Cloud Function or scheduled job
  Future<void> checkChallengeCompletions() async {
    try {
      // This would typically be implemented as a Cloud Function
      // that runs on a schedule
      log('checkChallengeCompletions: This should be implemented as a Cloud Function');
    } catch (e, stackTrace) {
      log('Error in checkChallengeCompletions: $e', stackTrace: stackTrace);
    }
  }

  /// Update rankings for a challenge
  ///
  /// Recalculates ranks based on current progress
  Future<void> updateChallengeRankings(String challengeId) async {
    try {
      await _repository.updateRankings(challengeId);
    } catch (e, stackTrace) {
      log('Error in updateChallengeRankings: $e', stackTrace: stackTrace);
    }
  }
}

