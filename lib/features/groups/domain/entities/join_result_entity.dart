/// Represents the result of attempting to join a group
class JoinResultEntity {
  final bool success;
  final String? errorMessage;
  final JoinErrorType? errorType;
  final GroupMembershipEntity? membership;

  const JoinResultEntity({
    required this.success,
    this.errorMessage,
    this.errorType,
    this.membership,
  });

  const JoinResultEntity.success(GroupMembershipEntity membership)
      : success = true,
        errorMessage = null,
        errorType = null,
        membership = membership;

  const JoinResultEntity.error(JoinErrorType type, String message)
      : success = false,
        errorType = type,
        errorMessage = message,
        membership = null;
}

/// Types of errors that can occur when joining a group
enum JoinErrorType {
  userBanned,
  genderMismatch,
  alreadyInGroup,
  cooldownActive,
  capacityFull,
  invalidJoinMethod,
  invalidCode,
  expiredCode,
  groupNotFound,
  groupInactive,
  groupPaused,
}

/// Represents the result of attempting to create a group
class CreateGroupResultEntity {
  final bool success;
  final String? errorMessage;
  final CreateGroupErrorType? errorType;
  final GroupMembershipEntity? membership;

  const CreateGroupResultEntity({
    required this.success,
    this.errorMessage,
    this.errorType,
    this.membership,
  });

  const CreateGroupResultEntity.success(GroupMembershipEntity membership)
      : success = true,
        errorMessage = null,
        errorType = null,
        membership = membership;

  const CreateGroupResultEntity.error(CreateGroupErrorType type, String message)
      : success = false,
        errorType = type,
        errorMessage = message,
        membership = null;
}

/// Types of errors that can occur when creating a group
enum CreateGroupErrorType {
  userBanned,
  alreadyInGroup,
  capacityRequiresPlusUser,
  invalidCapacity,
  invalidName,
  invalidGender,
  cooldownActive,
}

/// Represents the result of attempting to leave a group
class LeaveResultEntity {
  final bool success;
  final String? errorMessage;
  final DateTime? nextJoinAllowedAt;

  const LeaveResultEntity({
    required this.success,
    this.errorMessage,
    this.nextJoinAllowedAt,
  });

  const LeaveResultEntity.success(DateTime nextJoinAllowedAt)
      : success = true,
        errorMessage = null,
        nextJoinAllowedAt = nextJoinAllowedAt;

  const LeaveResultEntity.error(String message)
      : success = false,
        errorMessage = message,
        nextJoinAllowedAt = null;
}
