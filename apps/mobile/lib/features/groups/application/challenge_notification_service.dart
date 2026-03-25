import 'dart:developer';
import 'package:cloud_functions/cloud_functions.dart';
import '../domain/repositories/challenges_repository.dart';

/// Service for sending challenge-related notifications
///
/// Integrates with Firebase Cloud Functions to send timely alerts
class ChallengeNotificationService {
  final ChallengesRepository _repository;

  const ChallengeNotificationService(this._repository);

  /// Send daily reminder to complete tasks
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

      await FirebaseFunctions.instance
          .httpsCallable('sendChallengeNotification')
          .call({
        'type': 'daily_reminder',
        'challengeId': challengeId,
        'recipientCpId': cpId,
      });

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
      await FirebaseFunctions.instance
          .httpsCallable('sendChallengeNotification')
          .call({
        'type': 'milestone',
        'challengeId': challengeId,
        'recipientCpId': cpId,
        'data': {'milestone': milestone},
      });

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

      await FirebaseFunctions.instance
          .httpsCallable('sendChallengeNotification')
          .call({
        'type': 'challenge_complete',
        'challengeId': challengeId,
        'recipientCpId': cpId,
        'data': {'challengeName': challenge.name},
      });

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

      await FirebaseFunctions.instance
          .httpsCallable('sendChallengeNotification')
          .call({
        'type': 'rank_update',
        'challengeId': challengeId,
        'recipientCpId': cpId,
        'data': {'newRank': newRank, 'rankChange': rankChange},
      });

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

      await FirebaseFunctions.instance
          .httpsCallable('sendChallengeNotification')
          .call({
        'type': 'challenge_ending_soon',
        'challengeId': challengeId,
        'recipientCpId': cpId,
        'data': {
          'challengeName': challenge.name,
          'timeText': timeText,
        },
      });

      log('Challenge ending notification sent: $timeText for user $cpId');
    } catch (e, stackTrace) {
      log('Error sending ending notification: $e', stackTrace: stackTrace);
    }
  }

  /// Schedule daily reminders for a challenge
  ///
  /// Calls Cloud Function to set up recurring reminder schedule
  Future<void> scheduleDailyReminders(String challengeId) async {
    try {
      await FirebaseFunctions.instance
          .httpsCallable('scheduleChallengeReminders')
          .call({
        'challengeId': challengeId,
      });

      log('Daily reminders scheduled for challenge $challengeId');
    } catch (e, stackTrace) {
      log('Error scheduling daily reminders: $e', stackTrace: stackTrace);
    }
  }
}
