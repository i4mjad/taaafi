import 'dart:developer';
import '../domain/repositories/challenges_repository.dart';

/// Service for sending challenge-related notifications
///
/// Integrates with the app's notification system to send timely alerts
class ChallengeNotificationService {
  final ChallengesRepository _repository;

  const ChallengeNotificationService(this._repository);

  /// Send daily reminder to update progress
  ///
  /// Should be called by a scheduled notification or Cloud Function
  Future<void> sendDailyReminder({
    required String challengeId,
    required String cpId,
  }) async {
    try {
      final participation = await _repository.getParticipation(
        challengeId: challengeId,
        cpId: cpId,
      );

      if (participation == null) return;
      if (participation.hasUpdatedToday()) return;

      // TODO: Integrate with your notification service
      // Example:
      // await notificationService.sendNotification(
      //   userId: cpId,
      //   title: 'Challenge Reminder',
      //   body: 'Don\'t forget to update your progress today!',
      // );

      log('Daily reminder sent for challenge $challengeId to user $cpId');
    } catch (e, stackTrace) {
      log('Error sending daily reminder: $e', stackTrace: stackTrace);
    }
  }

  /// Send milestone notification
  ///
  /// Called when a user reaches 25%, 50%, 75%, or 100%
  Future<void> sendMilestoneNotification({
    required String challengeId,
    required String cpId,
    required int milestone,
  }) async {
    try {
      // TODO: Integrate with your notification service
      // Example:
      // await notificationService.sendNotification(
      //   userId: cpId,
      //   title: 'Milestone Reached! 🎉',
      //   body: 'You\'ve reached $milestone% in your challenge!',
      // );

      log('Milestone notification sent: $milestone% for user $cpId');
    } catch (e, stackTrace) {
      log('Error sending milestone notification: $e', stackTrace: stackTrace);
    }
  }

  /// Send challenge completion notification
  Future<void> sendChallengeCompleteNotification({
    required String challengeId,
    required String cpId,
  }) async {
    try {
      final challenge = await _repository.getChallengeById(challengeId);
      if (challenge == null) return;

      // TODO: Integrate with your notification service
      // Example:
      // await notificationService.sendNotification(
      //   userId: cpId,
      //   title: 'Challenge Completed! 🏆',
      //   body: 'Congratulations! You\'ve completed "${challenge.title}"',
      // );

      log('Challenge complete notification sent for user $cpId');
    } catch (e, stackTrace) {
      log('Error sending completion notification: $e', stackTrace: stackTrace);
    }
  }

  /// Send rank update notification
  ///
  /// Called when a user's rank changes significantly
  Future<void> sendRankUpdateNotification({
    required String challengeId,
    required String cpId,
    required int newRank,
    required int oldRank,
  }) async {
    try {
      final rankChange = oldRank - newRank; // Positive = moved up

      if (rankChange <= 0) return; // Only notify on improvements

      // TODO: Integrate with your notification service
      // Example:
      // await notificationService.sendNotification(
      //   userId: cpId,
      //   title: 'Rank Update! 📊',
      //   body: 'You moved up $rankChange positions! You\'re now #$newRank',
      // );

      log('Rank update notification sent: $oldRank -> $newRank for user $cpId');
    } catch (e, stackTrace) {
      log('Error sending rank update notification: $e', stackTrace: stackTrace);
    }
  }

  /// Send challenge ending soon notification
  ///
  /// Should be called 3 days, 1 day, and 6 hours before challenge ends
  Future<void> sendChallengeEndingSoonNotification({
    required String challengeId,
    required String cpId,
    required int hoursRemaining,
  }) async {
    try {
      final challenge = await _repository.getChallengeById(challengeId);
      if (challenge == null) return;

      String timeText;
      if (hoursRemaining >= 72) {
        timeText = '3 days';
      } else if (hoursRemaining >= 24) {
        timeText = '1 day';
      } else {
        timeText = '$hoursRemaining hours';
      }

      // TODO: Integrate with your notification service
      // Example:
      // await notificationService.sendNotification(
      //   userId: cpId,
      //   title: 'Challenge Ending Soon! ⏰',
      //   body: '"${challenge.title}" ends in $timeText',
      // );

      log('Challenge ending notification sent: $timeText for user $cpId');
    } catch (e, stackTrace) {
      log('Error sending ending notification: $e', stackTrace: stackTrace);
    }
  }

  /// Schedule daily reminders for a challenge
  ///
  /// Should be implemented with Cloud Functions scheduled tasks
  Future<void> scheduleDailyReminders(String challengeId) async {
    try {
      // TODO: Implement with Cloud Functions
      // This would set up a recurring scheduled task to check
      // all participants and send reminders at a specific time (e.g., 8 PM)

      log('Daily reminders scheduled for challenge $challengeId');
    } catch (e, stackTrace) {
      log('Error scheduling daily reminders: $e', stackTrace: stackTrace);
    }
  }
}

