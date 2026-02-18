/// Result entities for challenge operations
///
/// These entities represent the results of challenge actions

/// Result of challenge creation
class CreateChallengeResult {
  final bool success;
  final String? challengeId;
  final CreateChallengeError? error;
  final String? errorMessage;

  const CreateChallengeResult({
    required this.success,
    this.challengeId,
    this.error,
    this.errorMessage,
  });

  const CreateChallengeResult.success(this.challengeId)
      : success = true,
        error = null,
        errorMessage = null;

  const CreateChallengeResult.failure(this.error, this.errorMessage)
      : success = false,
        challengeId = null;
}

/// Possible errors when creating a challenge
enum CreateChallengeError {
  invalidTitle,
  invalidDescription,
  invalidDates,
  invalidGoal,
  notGroupMember,
  notAuthorized,
  unknown,
}

/// Result of joining a challenge
class JoinChallengeResult {
  final bool success;
  final String? participationId;
  final JoinChallengeError? error;
  final String? errorMessage;

  const JoinChallengeResult({
    required this.success,
    this.participationId,
    this.error,
    this.errorMessage,
  });

  const JoinChallengeResult.success(this.participationId)
      : success = true,
        error = null,
        errorMessage = null;

  const JoinChallengeResult.failure(this.error, this.errorMessage)
      : success = false,
        participationId = null;
}

/// Possible errors when joining a challenge
enum JoinChallengeError {
  challengeNotFound,
  challengeNotActive,
  challengeFull,
  alreadyJoined,
  lateJoinNotAllowed,
  notGroupMember,
  unknown,
}

/// Result of leaving a challenge
class LeaveChallengeResult {
  final bool success;
  final LeaveChallengeError? error;
  final String? errorMessage;

  const LeaveChallengeResult({
    required this.success,
    this.error,
    this.errorMessage,
  });

  const LeaveChallengeResult.success()
      : success = true,
        error = null,
        errorMessage = null;

  const LeaveChallengeResult.failure(this.error, this.errorMessage)
      : success = false;
}

/// Possible errors when leaving a challenge
enum LeaveChallengeError {
  notParticipating,
  challengeCompleted,
  unknown,
}

/// Result of updating progress
class UpdateProgressResult {
  final bool success;
  final int? newProgress;
  final int? newCurrentValue;
  final bool isCompleted;
  final int? milestoneReached; // 25, 50, 75, 100
  final UpdateProgressError? error;
  final String? errorMessage;

  const UpdateProgressResult({
    required this.success,
    this.newProgress,
    this.newCurrentValue,
    this.isCompleted = false,
    this.milestoneReached,
    this.error,
    this.errorMessage,
  });

  const UpdateProgressResult.success({
    required this.newProgress,
    required this.newCurrentValue,
    this.isCompleted = false,
    this.milestoneReached,
  })  : success = true,
        error = null,
        errorMessage = null;

  const UpdateProgressResult.failure(this.error, this.errorMessage)
      : success = false,
        newProgress = null,
        newCurrentValue = null,
        isCompleted = false,
        milestoneReached = null;
}

/// Possible errors when updating progress
enum UpdateProgressError {
  notParticipating,
  challengeNotActive,
  invalidValue,
  alreadyCompleted,
  unknown,
}

/// Result of deleting a challenge
class DeleteChallengeResult {
  final bool success;
  final DeleteChallengeError? error;
  final String? errorMessage;

  const DeleteChallengeResult({
    required this.success,
    this.error,
    this.errorMessage,
  });

  const DeleteChallengeResult.success()
      : success = true,
        error = null,
        errorMessage = null;

  const DeleteChallengeResult.failure(this.error, this.errorMessage)
      : success = false;
}

/// Possible errors when deleting a challenge
enum DeleteChallengeError {
  notAuthorized,
  challengeNotFound,
  unknown,
}

