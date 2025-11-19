import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../domain/repositories/challenges_repository.dart';
import '../domain/services/challenges_service.dart';
import '../domain/entities/challenge_entity.dart';
import '../domain/entities/challenge_participation_entity.dart';
import '../domain/entities/challenge_stats_entity.dart';
import '../domain/entities/challenge_update_entity.dart';
import '../domain/entities/challenge_task_instance.dart';
import '../data/repositories/challenges_repository_impl.dart';
import 'challenge_progress_tracker_service.dart';
import 'challenge_notification_service.dart';
import 'challenge_history_service.dart';
import 'groups_providers.dart' as groups;
import '../../community/presentation/providers/community_providers_new.dart';

part 'challenges_providers.g.dart';

// ============================================
// Repository Provider
// ============================================

@riverpod
ChallengesRepository challengesRepository(ref) {
  final firestore = ref.watch(groups.firestoreProvider);
  return ChallengesRepositoryImpl(firestore);
}

// ============================================
// Service Providers
// ============================================

@riverpod
ChallengesService challengesService(ref) {
  final repository = ref.watch(challengesRepositoryProvider);
  final groupsRepository = ref.watch(groups.groupsRepositoryProvider);
  return ChallengesService(repository, groupsRepository);
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

/// Get user's participation in a specific challenge (Stream for real-time updates)
@riverpod
Stream<ChallengeParticipationEntity?> userChallengeParticipation(
  ref,
  String challengeId,
  String cpId,
) {
  final repository = ref.watch(challengesRepositoryProvider);
  return repository.watchParticipation(
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

// ============================================
// Task History Providers
// ============================================

/// Get task instances for a challenge (for the current user)
/// Loads challenge, user participation, and generates task instances
/// Uses Stream to watch for real-time updates
@riverpod
Stream<List<ChallengeTaskInstance>> challengeTaskInstances(
  ref,
  String challengeId,
) async* {
  // Get challenge
  final challenge = await ref.watch(challengeByIdProvider(challengeId).future);

  if (challenge == null) {
    yield [];
    return;
  }

  // Get current user profile
  final profile = await ref.watch(currentCommunityProfileProvider.future);

  if (profile == null) {
    yield [];
    return;
  }

  // Watch user's participation for real-time updates
  final repository = ref.watch(challengesRepositoryProvider);
  final participationStream = repository.watchParticipation(
    challengeId: challengeId,
    cpId: profile.id,
  );

  // Transform the participation stream into task instances stream
  await for (final participation in participationStream) {
    if (participation == null) {
      yield [];
      continue;
    }

    // Generate task instances using the history service
    final historyService = ChallengeHistoryService();
    final instances = historyService.generateTaskInstances(
      challenge: challenge,
      participation: participation,
    );
    
    yield instances;
  }
}

/// Get today's task instances across all challenges in a group (for the current user)
@riverpod
Future<List<ChallengeTaskInstance>> groupTodayTasks(
  ref,
  String groupId,
) async {
  print('🔍 ============ GROUP TODAY TASKS DEBUG ============');
  print('📋 Loading tasks for group: $groupId');

  // Get current user profile
  final profile = await ref.watch(currentCommunityProfileProvider.future);

  if (profile == null) {
    print('❌ No profile found');
    return [];
  }
  print('✅ Profile found: ${profile.id}');

  // Get all active challenges in this group
  final challenges = await ref.watch(activeChallengesProvider(groupId).future);
  print('📊 Found ${challenges.length} active challenges');

  final todayTasks = <ChallengeTaskInstance>[];
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  // For each challenge, get the user's task instances and filter for today
  for (final challenge in challenges) {
    print('\n🎯 Challenge: "${challenge.name}" (${challenge.id})');
    print('   Tasks in challenge: ${challenge.tasks.length}');

    // Get user's participation (take first from stream)
    final participation = await ref.watch(
      userChallengeParticipationProvider(challenge.id, profile.id).future,
    );

    if (participation == null) {
      print('   ⚠️ User not participating in this challenge');
      continue;
    }
    
    // Skip if user quit the challenge
    if (participation.hasQuit()) {
      print('   ⚠️ User has quit this challenge');
      continue;
    }
    
    print('   ✅ User is participating');
    print('   Completions: ${participation.taskCompletions.length}');

    // Generate ONLY today's task instances (more efficient)
    final historyService = ChallengeHistoryService();
    final todayInstances = historyService.generateTodayTaskInstances(
      challenge: challenge,
      participation: participation,
    );
    print('   Generated ${todayInstances.length} task instances for today');

    // Log each task
    for (final instance in todayInstances) {
      print(
          '   🔸 ${instance.task.frequency.name} task: "${instance.task.name}" - Status: ${instance.status.name}');
    }

    todayTasks.addAll(todayInstances);
  }

  print('\n✅ Total tasks for today: ${todayTasks.length}');
  print('🔍 ============ END DEBUG ============\n');
  return todayTasks;
}
