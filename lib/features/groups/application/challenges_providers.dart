import 'package:reboot_app_3/features/groups/domain/entities/challenge_task_entity.dart';
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

// ============================================
// Task History Providers
// ============================================

/// Get task instances for a challenge (for the current user)
/// Loads challenge, user participation, and generates task instances
@riverpod
Future<List<ChallengeTaskInstance>> challengeTaskInstances(
  ref,
  String challengeId,
) async {
  // Get challenge
  final challenge = await ref.watch(challengeByIdProvider(challengeId).future);

  if (challenge == null) {
    return [];
  }

  // Get current user profile
  final profile = await ref.watch(currentCommunityProfileProvider.future);

  if (profile == null) {
    return [];
  }

  // Get user's participation in this challenge
  final participation = await ref.watch(
    userChallengeParticipationProvider(challengeId, profile.id).future,
  );

  if (participation == null) {
    return [];
  }

  // Generate task instances using the history service
  final historyService = ChallengeHistoryService();
  return historyService.generateTaskInstances(
    challenge: challenge,
    participation: participation,
  );
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
    
    // Get user's participation
    final participation = await ref.watch(
      userChallengeParticipationProvider(challenge.id, profile.id).future,
    );

    if (participation == null) {
      print('   ⚠️ User not participating in this challenge');
      continue;
    }
    print('   ✅ User is participating');
    print('   Completions: ${participation.taskCompletions.length}');

    // Generate task instances
    final historyService = ChallengeHistoryService();
    final instances = historyService.generateTaskInstances(
      challenge: challenge,
      participation: participation,
    );
    print('   Generated ${instances.length} task instances');

    // Filter for today's tasks
    final todayInstances = instances.where((instance) {
      // For one-time tasks: show if not completed (regardless of date)
      if (instance.task.frequency == TaskFrequency.oneTime) {
        final isCompleted = instance.status == TaskInstanceStatus.completed;
        print('   🔸 One-time task: "${instance.task.name}" - Completed: $isCompleted');
        return !isCompleted;
      }

      // For daily/weekly tasks: show only if scheduled for today
      final isToday = instance.scheduledDate.year == today.year &&
          instance.scheduledDate.month == today.month &&
          instance.scheduledDate.day == today.day;
      if (isToday) {
        print('   🔸 ${instance.task.frequency.name} task: "${instance.task.name}" - Status: ${instance.status.name}');
      }
      return isToday;
    }).toList();

    print('   ➡️ Filtered to ${todayInstances.length} tasks for today');
    todayTasks.addAll(todayInstances);
  }

  print('\n✅ Total tasks for today: ${todayTasks.length}');
  print('🔍 ============ END DEBUG ============\n');
  return todayTasks;
}
