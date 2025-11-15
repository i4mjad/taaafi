import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../domain/repositories/challenges_repository.dart';
import '../domain/services/challenges_service.dart';
import '../domain/entities/challenge_entity.dart';
import '../domain/entities/challenge_participation_entity.dart';
import '../domain/entities/challenge_stats_entity.dart';
import '../domain/entities/challenge_update_entity.dart';
import '../data/repositories/challenges_repository_impl.dart';
import 'challenge_progress_tracker_service.dart';
import 'challenge_notification_service.dart';
import 'groups_providers.dart';

part 'challenges_providers.g.dart';

// ============================================
// Repository Provider
// ============================================

@riverpod
ChallengesRepository challengesRepository(ref) {
  final firestore = ref.watch(firestoreProvider);
  return ChallengesRepositoryImpl(firestore);
}

// ============================================
// Service Providers
// ============================================

@riverpod
ChallengesService challengesService(ref) {
  final repository = ref.watch(challengesRepositoryProvider);
  return ChallengesService(repository);
}

@riverpod
ChallengeProgressTrackerService challengeProgressTrackerService(ref) {
  final repository = ref.watch(challengesRepositoryProvider);
  return ChallengeProgressTrackerService(repository);
}

@riverpod
ChallengeNotificationService challengeNotificationService(ref) {
  final repository = ref.watch(challengesRepositoryProvider);
  return ChallengeNotificationService(repository);
}

// ============================================
// Challenge Query Providers
// ============================================

/// Get all challenges for a group
@riverpod
Future<List<ChallengeEntity>> groupChallenges(ref, String groupId) async {
  final service = ref.watch(challengesServiceProvider);
  return await service.getGroupChallenges(groupId);
}

/// Get active challenges for a group
@riverpod
Future<List<ChallengeEntity>> activeChallenges(ref, String groupId) async {
  final service = ref.watch(challengesServiceProvider);
  return await service.getActiveChallenges(groupId);
}

/// Get completed challenges for a group
@riverpod
Future<List<ChallengeEntity>> completedChallenges(
  ref,
  String groupId,
) async {
  final service = ref.watch(challengesServiceProvider);
  return await service.getCompletedChallenges(groupId);
}

/// Get a single challenge by ID
@riverpod
Future<ChallengeEntity?> challengeById(ref, String challengeId) async {
  final service = ref.watch(challengesServiceProvider);
  return await service.getChallengeById(challengeId);
}

// ============================================
// Participation Query Providers
// ============================================

/// Get user's participation in a specific challenge
@riverpod
Future<ChallengeParticipationEntity?> userChallengeParticipation(
  ref,
  String challengeId,
  String cpId,
) async {
  final service = ref.watch(challengesServiceProvider);
  return await service.getParticipation(
    challengeId: challengeId,
    cpId: cpId,
  );
}

/// Get user's active challenges
@riverpod
Future<List<ChallengeParticipationEntity>> userActiveChallenges(
  ref,
  String cpId,
) async {
  final service = ref.watch(challengesServiceProvider);
  return await service.getUserActiveChallenges(cpId);
}

// ============================================
// Leaderboard & Stats Providers
// ============================================

/// Get leaderboard for a challenge
@riverpod
Future<List<ChallengeParticipationEntity>> challengeLeaderboard(
  ref,
  String challengeId, {
  int limit = 50,
}) async {
  final service = ref.watch(challengesServiceProvider);
  return await service.getLeaderboard(
    challengeId: challengeId,
    limit: limit,
  );
}

/// Get challenge statistics
@riverpod
Future<ChallengeStatsEntity> challengeStats(
  ref,
  String challengeId,
) async {
  final service = ref.watch(challengesServiceProvider);
  return await service.getChallengeStats(challengeId);
}

// ============================================
// Updates/Feed Providers
// ============================================

/// Get recent updates for a challenge
@riverpod
Future<List<ChallengeUpdateEntity>> challengeUpdates(
  ref,
  String challengeId, {
  int limit = 20,
}) async {
  final service = ref.watch(challengesServiceProvider);
  return await service.getChallengeUpdates(
    challengeId: challengeId,
    limit: limit,
  );
}

