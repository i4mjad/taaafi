import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../domain/entities/challenge_entity.dart';
import '../application/challenges_providers.dart';

part 'challenges_notifier.g.dart';

/// State for challenges list
class ChallengesState {
  final List<ChallengeEntity> activeChallenges;
  final List<ChallengeEntity> upcomingChallenges;
  final List<ChallengeEntity> completedChallenges;
  final bool isRefreshing;
  final String? error;

  const ChallengesState({
    this.activeChallenges = const [],
    this.upcomingChallenges = const [],
    this.completedChallenges = const [],
    this.isRefreshing = false,
    this.error,
  });

  ChallengesState copyWith({
    List<ChallengeEntity>? activeChallenges,
    List<ChallengeEntity>? upcomingChallenges,
    List<ChallengeEntity>? completedChallenges,
    bool? isRefreshing,
    String? error,
  }) {
    return ChallengesState(
      activeChallenges: activeChallenges ?? this.activeChallenges,
      upcomingChallenges: upcomingChallenges ?? this.upcomingChallenges,
      completedChallenges: completedChallenges ?? this.completedChallenges,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      error: error,
    );
  }
}

/// Notifier for managing challenges list state
@riverpod
class ChallengesNotifier extends _$ChallengesNotifier {
  @override
  Future<ChallengesState> build(String groupId) async {
    try {
      // Fetch all challenges
      final challenges = await ref.watch(groupChallengesProvider(groupId).future);

      // Categorize challenges
      final active = challenges
          .where((c) => c.status == ChallengeStatus.active)
          .toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

      final upcoming = challenges
          .where((c) => c.status == ChallengeStatus.draft)
          .toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

      final completed = challenges
          .where((c) => c.status == ChallengeStatus.completed)
          .toList()
        ..sort((a, b) => b.endDate.compareTo(a.endDate));

      return ChallengesState(
        activeChallenges: active,
        upcomingChallenges: upcoming,
        completedChallenges: completed,
      );
    } catch (e) {
      return ChallengesState(error: e.toString());
    }
  }

  /// Refresh challenges data
  Future<void> refresh() async {
    // Invalidate and rebuild
    ref.invalidateSelf();
  }
}

