import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../domain/entities/challenge_entity.dart';
import '../domain/entities/challenge_result_entities.dart';
import '../application/challenges_providers.dart';
import '../../community/presentation/providers/community_providers_new.dart';

part 'challenge_creation_notifier.g.dart';

/// State for challenge creation form
class ChallengeCreationState {
  // Basic info
  final ChallengeType type;
  final String title;
  final String description;

  // Duration
  final DateTime? startDate;
  final DateTime? endDate;
  final int durationDays;

  // Goal
  final GoalType? goalType;
  final int? goalTarget;
  final String? goalUnit;

  // Settings
  final int? maxParticipants;
  final bool allowLateJoin;
  final bool notifyOnMilestone;
  final int pointsReward;

  // UI state
  final bool isLoading;
  final String? error;
  final Map<String, String> validationErrors;

  const ChallengeCreationState({
    this.type = ChallengeType.duration,
    this.title = '',
    this.description = '',
    this.startDate,
    this.endDate,
    this.durationDays = 30,
    this.goalType,
    this.goalTarget,
    this.goalUnit,
    this.maxParticipants,
    this.allowLateJoin = true,
    this.notifyOnMilestone = true,
    this.pointsReward = 10,
    this.isLoading = false,
    this.error,
    this.validationErrors = const {},
  });

  ChallengeCreationState copyWith({
    ChallengeType? type,
    String? title,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    int? durationDays,
    GoalType? goalType,
    int? goalTarget,
    String? goalUnit,
    int? maxParticipants,
    bool? allowLateJoin,
    bool? notifyOnMilestone,
    int? pointsReward,
    bool? isLoading,
    String? error,
    Map<String, String>? validationErrors,
  }) {
    return ChallengeCreationState(
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      durationDays: durationDays ?? this.durationDays,
      goalType: goalType ?? this.goalType,
      goalTarget: goalTarget ?? this.goalTarget,
      goalUnit: goalUnit ?? this.goalUnit,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      allowLateJoin: allowLateJoin ?? this.allowLateJoin,
      notifyOnMilestone: notifyOnMilestone ?? this.notifyOnMilestone,
      pointsReward: pointsReward ?? this.pointsReward,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      validationErrors: validationErrors ?? this.validationErrors,
    );
  }

  /// Validate form
  Map<String, String> validate() {
    final errors = <String, String>{};

    if (title.trim().isEmpty) {
      errors['title'] = 'Title is required';
    } else if (title.length > 60) {
      errors['title'] = 'Title must be 60 characters or less';
    }

    if (description.trim().isEmpty) {
      errors['description'] = 'Description is required';
    } else if (description.length > 500) {
      errors['description'] = 'Description must be 500 characters or less';
    }

    if (startDate == null) {
      errors['startDate'] = 'Start date is required';
    }

    if (endDate == null) {
      errors['endDate'] = 'End date is required';
    }

    if (startDate != null && endDate != null && endDate!.isBefore(startDate!)) {
      errors['endDate'] = 'End date must be after start date';
    }

    if (type == ChallengeType.goal || type == ChallengeType.team) {
      if (goalType == null) {
        errors['goalType'] = 'Goal type is required';
      }
      if (goalTarget == null || goalTarget! <= 0) {
        errors['goalTarget'] = 'Goal target must be greater than 0';
      }
    }

    return errors;
  }
}

/// Notifier for challenge creation form
@riverpod
class ChallengeCreationNotifier extends _$ChallengeCreationNotifier {
  @override
  ChallengeCreationState build() {
    // Initialize with default values
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));
    final endDate = tomorrow.add(const Duration(days: 30));

    return ChallengeCreationState(
      startDate: tomorrow,
      endDate: endDate,
    );
  }

  /// Update challenge type
  void setType(ChallengeType type) {
    state = state.copyWith(type: type);
  }

  /// Update title
  void setTitle(String title) {
    state = state.copyWith(title: title);
  }

  /// Update description
  void setDescription(String description) {
    state = state.copyWith(description: description);
  }

  /// Update start date
  void setStartDate(DateTime date) {
    state = state.copyWith(startDate: date);

    // Auto-calculate end date if duration is set
    if (state.durationDays > 0) {
      final endDate = date.add(Duration(days: state.durationDays));
      state = state.copyWith(endDate: endDate);
    }
  }

  /// Update end date
  void setEndDate(DateTime date) {
    state = state.copyWith(endDate: date);

    // Update duration
    if (state.startDate != null) {
      final duration = date.difference(state.startDate!).inDays;
      state = state.copyWith(durationDays: duration);
    }
  }

  /// Update duration
  void setDuration(int days) {
    state = state.copyWith(durationDays: days);

    // Auto-calculate end date if start date is set
    if (state.startDate != null) {
      final endDate = state.startDate!.add(Duration(days: days));
      state = state.copyWith(endDate: endDate);
    }
  }

  /// Update goal type
  void setGoalType(GoalType? goalType) {
    state = state.copyWith(goalType: goalType);
  }

  /// Update goal target
  void setGoalTarget(int? target) {
    state = state.copyWith(goalTarget: target);
  }

  /// Update goal unit
  void setGoalUnit(String? unit) {
    state = state.copyWith(goalUnit: unit);
  }

  /// Update max participants
  void setMaxParticipants(int? max) {
    state = state.copyWith(maxParticipants: max);
  }

  /// Toggle allow late join
  void toggleAllowLateJoin() {
    state = state.copyWith(allowLateJoin: !state.allowLateJoin);
  }

  /// Toggle notify on milestone
  void toggleNotifyOnMilestone() {
    state = state.copyWith(notifyOnMilestone: !state.notifyOnMilestone);
  }

  /// Update points reward
  void setPointsReward(int points) {
    state = state.copyWith(pointsReward: points);
  }

  /// Submit and create challenge
  Future<CreateChallengeResult> submit(String groupId) async {
    // Validate
    final validationErrors = state.validate();
    if (validationErrors.isNotEmpty) {
      state = state.copyWith(validationErrors: validationErrors);
      return const CreateChallengeResult.failure(
        CreateChallengeError.invalidTitle,
        'Please fix validation errors',
      );
    }

    // Get user profile
    final profile = await ref.read(currentCommunityProfileProvider.future);
    if (profile == null) {
      return const CreateChallengeResult.failure(
        CreateChallengeError.notAuthorized,
        'You must be logged in',
      );
    }

    // Set loading
    state = state.copyWith(isLoading: true);

    try {
      final service = ref.read(challengesServiceProvider);
      final result = await service.createChallenge(
        groupId: groupId,
        creatorCpId: profile.id,
        title: state.title,
        description: state.description,
        type: state.type,
        startDate: state.startDate!,
        endDate: state.endDate!,
        durationDays: state.durationDays,
        goalType: state.goalType,
        goalTarget: state.goalTarget,
        goalUnit: state.goalUnit,
        maxParticipants: state.maxParticipants,
        allowLateJoin: state.allowLateJoin,
        notifyOnMilestone: state.notifyOnMilestone,
        pointsReward: state.pointsReward,
      );

      if (result.success) {
        // Reset form
        final now = DateTime.now();
        final tomorrow = now.add(const Duration(days: 1));
        final endDate = tomorrow.add(const Duration(days: 30));

        state = ChallengeCreationState(
          startDate: tomorrow,
          endDate: endDate,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: result.errorMessage,
        );
      }

      return result;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return const CreateChallengeResult.failure(
        CreateChallengeError.unknown,
        'Failed to create challenge',
      );
    }
  }

  /// Reset form
  void reset() {
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));
    final endDate = tomorrow.add(const Duration(days: 30));

    state = ChallengeCreationState(
      startDate: tomorrow,
      endDate: endDate,
    );
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null, validationErrors: {});
  }
}

