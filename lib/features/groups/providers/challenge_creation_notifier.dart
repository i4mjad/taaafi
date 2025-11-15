import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../domain/entities/challenge_task_entity.dart';
import '../domain/entities/challenge_result_entities.dart';
import '../application/challenges_providers.dart';
import '../../community/presentation/providers/community_providers_new.dart';

part 'challenge_creation_notifier.g.dart';

/// State for challenge creation form
class ChallengeCreationState {
  // Basic info
  final String name;
  final DateTime? endDate;
  final String color;
  final List<ChallengeTaskEntity> tasks;

  // UI state
  final bool isLoading;
  final String? error;
  final Map<String, String> validationErrors;

  const ChallengeCreationState({
    this.name = '',
    this.endDate,
    this.color = 'blue',
    this.tasks = const [],
    this.isLoading = false,
    this.error,
    this.validationErrors = const {},
  });

  ChallengeCreationState copyWith({
    String? name,
    DateTime? endDate,
    String? color,
    List<ChallengeTaskEntity>? tasks,
    bool? isLoading,
    String? error,
    Map<String, String>? validationErrors,
  }) {
    return ChallengeCreationState(
      name: name ?? this.name,
      endDate: endDate ?? this.endDate,
      color: color ?? this.color,
      tasks: tasks ?? this.tasks,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      validationErrors: validationErrors ?? this.validationErrors,
    );
  }

  /// Validate form
  Map<String, String> validate() {
    final errors = <String, String>{};

    if (name.trim().isEmpty) {
      errors['name'] = 'Challenge name is required';
    } else if (name.length > 60) {
      errors['name'] = 'Name must be 60 characters or less';
    }

    if (endDate == null) {
      errors['endDate'] = 'End date is required';
    }

    if (tasks.isEmpty) {
      errors['tasks'] = 'At least one task is required';
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
    final endDate = DateTime.now().add(const Duration(days: 30));

    return ChallengeCreationState(
      endDate: endDate,
    );
  }

  /// Update challenge name
  void setName(String name) {
    state = state.copyWith(name: name);
  }

  /// Update end date
  void setEndDate(DateTime date) {
    state = state.copyWith(endDate: date);
  }

  /// Update color
  void setColor(String color) {
    state = state.copyWith(color: color);
  }

  /// Add a task
  void addTask(ChallengeTaskEntity task) {
    final updatedTasks = [...state.tasks, task];
    state = state.copyWith(tasks: updatedTasks);
  }

  /// Remove a task
  void removeTask(int index) {
    final updatedTasks = List<ChallengeTaskEntity>.from(state.tasks);
    updatedTasks.removeAt(index);
    state = state.copyWith(tasks: updatedTasks);
  }

  /// Update a task
  void updateTask(int index, ChallengeTaskEntity task) {
    final updatedTasks = List<ChallengeTaskEntity>.from(state.tasks);
    updatedTasks[index] = task;
    state = state.copyWith(tasks: updatedTasks);
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
        name: state.name,
        endDate: state.endDate!,
        color: state.color,
        tasks: state.tasks,
      );

      if (result.success) {
        // Reset form
        final endDate = DateTime.now().add(const Duration(days: 30));
        state = ChallengeCreationState(endDate: endDate);
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
    final endDate = DateTime.now().add(const Duration(days: 30));
    state = ChallengeCreationState(endDate: endDate);
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null, validationErrors: {});
  }
}

