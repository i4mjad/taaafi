import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../domain/entities/challenge_entity.dart';
import '../domain/entities/challenge_participation_entity.dart';
import '../domain/entities/challenge_stats_entity.dart';
import '../application/challenges_providers.dart';
import '../../community/presentation/providers/community_providers_new.dart';

part 'challenge_detail_notifier.g.dart';

/// State for challenge detail
class ChallengeDetailState {
  final ChallengeEntity? challenge;
  final List<ChallengeParticipationEntity> leaderboard;
  final ChallengeStatsEntity? stats;
  final ChallengeParticipationEntity? userParticipation;
  final bool isLoading;
  final String? error;
  final String? successMessage;

  const ChallengeDetailState({
    this.challenge,
    this.leaderboard = const [],
    this.stats,
    this.userParticipation,
    this.isLoading = false,
    this.error,
    this.successMessage,
  });

  ChallengeDetailState copyWith({
    ChallengeEntity? challenge,
    List<ChallengeParticipationEntity>? leaderboard,
    ChallengeStatsEntity? stats,
    ChallengeParticipationEntity? userParticipation,
    bool? isLoading,
    String? error,
    String? successMessage,
  }) {
    return ChallengeDetailState(
      challenge: challenge ?? this.challenge,
      leaderboard: leaderboard ?? this.leaderboard,
      stats: stats ?? this.stats,
      userParticipation: userParticipation ?? this.userParticipation,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      successMessage: successMessage,
    );
  }
}

/// Notifier for managing challenge detail state
@riverpod
class ChallengeDetailNotifier extends _$ChallengeDetailNotifier {
  @override
  Future<ChallengeDetailState> build(String challengeId) async {
    try {
      // Fetch challenge details
      final challenge =
          await ref.watch(challengeByIdProvider(challengeId).future);

      if (challenge == null) {
        return const ChallengeDetailState(
          error: 'Challenge not found',
        );
      }

      // Fetch leaderboard
      final leaderboard =
          await ref.watch(challengeLeaderboardProvider(challengeId).future);

      // Fetch stats
      final stats = await ref.watch(challengeStatsProvider(challengeId).future);

      // Fetch user's participation if they have a profile
      ChallengeParticipationEntity? userParticipation;
      final profile = await ref.watch(currentCommunityProfileProvider.future);
      if (profile != null) {
        userParticipation = await ref.watch(
            userChallengeParticipationProvider(challengeId, profile.id).future);
      }

      return ChallengeDetailState(
        challenge: challenge,
        leaderboard: leaderboard,
        stats: stats,
        userParticipation: userParticipation,
      );
    } catch (e) {
      return ChallengeDetailState(error: e.toString());
    }
  }

  /// Join the challenge
  Future<void> joinChallenge() async {
    final currentState = await future;
    if (currentState.challenge == null) return;

    // Get current user profile
    final profile = await ref.read(currentCommunityProfileProvider.future);
    if (profile == null) {
      state = AsyncValue.data(currentState.copyWith(
        error: 'You must be logged in to join a challenge',
      ));
      return;
    }

    // Set loading state
    state = AsyncValue.data(currentState.copyWith(isLoading: true));

    try {
      final service = ref.read(challengesServiceProvider);
      final result = await service.joinChallenge(
        challengeId: currentState.challenge!.id,
        cpId: profile.id,
      );

      if (result.success) {
        // Refresh state
        ref.invalidateSelf();
        state = AsyncValue.data(currentState.copyWith(
          isLoading: false,
          successMessage: 'Successfully joined the challenge!',
        ));
      } else {
        state = AsyncValue.data(currentState.copyWith(
          isLoading: false,
          error: result.errorMessage ?? 'Failed to join challenge',
        ));
      }
    } catch (e) {
      state = AsyncValue.data(currentState.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  /// Leave the challenge
  Future<void> leaveChallenge() async {
    final currentState = await future;
    if (currentState.challenge == null) return;

    // Get current user profile
    final profile = await ref.read(currentCommunityProfileProvider.future);
    if (profile == null) return;

    // Set loading state
    state = AsyncValue.data(currentState.copyWith(isLoading: true));

    try {
      final service = ref.read(challengesServiceProvider);
      final result = await service.leaveChallenge(
        challengeId: currentState.challenge!.id,
        cpId: profile.id,
      );

      if (result.success) {
        // Refresh state
        ref.invalidateSelf();
        state = AsyncValue.data(currentState.copyWith(
          isLoading: false,
          successMessage: 'Successfully left the challenge',
        ));
      } else {
        state = AsyncValue.data(currentState.copyWith(
          isLoading: false,
          error: result.errorMessage ?? 'Failed to leave challenge',
        ));
      }
    } catch (e) {
      state = AsyncValue.data(currentState.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  /// Complete a task
  Future<void> completeTask(String taskId, int points) async {
    final currentState = await future;
    if (currentState.challenge == null) return;

    // Get current user profile
    final profile = await ref.read(currentCommunityProfileProvider.future);
    if (profile == null) return;

    // Set loading state
    state = AsyncValue.data(currentState.copyWith(isLoading: true));

    try {
      final service = ref.read(challengesServiceProvider);
      final result = await service.completeTask(
        challengeId: currentState.challenge!.id,
        cpId: profile.id,
        taskId: taskId,
        pointsEarned: points,
      );

      if (result.success) {
        // Refresh state
        ref.invalidateSelf();

        String message = 'Task completed! +$points points';
        if (result.isCompleted) {
          message = 'Challenge completed! 🎉';
        }

        state = AsyncValue.data(currentState.copyWith(
          isLoading: false,
          successMessage: message,
        ));
      } else {
        state = AsyncValue.data(currentState.copyWith(
          isLoading: false,
          error: result.errorMessage ?? 'Failed to complete task',
        ));
      }
    } catch (e) {
      state = AsyncValue.data(currentState.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  /// Refresh challenge data
  Future<void> refresh() async {
    ref.invalidateSelf();
  }

  /// Clear messages
  void clearMessages() {
    state.whenData((currentState) {
      if (currentState.error != null || currentState.successMessage != null) {
        state = AsyncValue.data(currentState.copyWith(
          error: null,
          successMessage: null,
        ));
      }
    });
  }
}

