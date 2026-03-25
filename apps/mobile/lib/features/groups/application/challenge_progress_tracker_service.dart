import 'dart:developer';
import '../domain/entities/challenge_task_entity.dart';
import '../domain/repositories/challenges_repository.dart';

/// Service for automatically tracking challenge progress based on user activities
///
/// This service listens to user activities and updates challenge progress accordingly
class ChallengeProgressTrackerService {
  final ChallengesRepository _repository;

  const ChallengeProgressTrackerService(this._repository);

  /// Track when a user sends a message
  ///
  /// Checks active challenges for messageCount tasks and increments progress
  Future<void> trackMessageSent({
    required String cpId,
    required String groupId,
  }) async {
    try {
      final participations = await _repository.getUserActiveChallenges(cpId);

      for (final participation in participations) {
        final challenge =
            await _repository.getChallengeById(participation.challengeId);
        if (challenge == null) continue;

        for (final task in challenge.tasks) {
          if (task.taskType != TaskType.messageCount) continue;
          if (!participation.canCompleteTask(task.id, task.frequency)) continue;

          await _repository.completeTask(
            challengeId: participation.challengeId,
            cpId: cpId,
            taskId: task.id,
            pointsEarned: task.points,
          );

          log('Auto-completed messageCount task ${task.id} for $cpId in challenge ${participation.challengeId}');
        }
      }
    } catch (e, stackTrace) {
      log('Error in trackMessageSent: $e', stackTrace: stackTrace);
    }
  }

  /// Track daily activity
  ///
  /// Checks active challenges for dailyCheckin tasks and increments progress
  Future<void> trackDailyActivity({
    required String cpId,
  }) async {
    try {
      final participations = await _repository.getUserActiveChallenges(cpId);

      for (final participation in participations) {
        final challenge =
            await _repository.getChallengeById(participation.challengeId);
        if (challenge == null) continue;

        for (final task in challenge.tasks) {
          if (task.taskType != TaskType.dailyCheckin) continue;
          if (!participation.canCompleteTask(task.id, task.frequency)) continue;

          await _repository.completeTask(
            challengeId: participation.challengeId,
            cpId: cpId,
            taskId: task.id,
            pointsEarned: task.points,
          );

          log('Auto-completed dailyCheckin task ${task.id} for $cpId in challenge ${participation.challengeId}');
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
