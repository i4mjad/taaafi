/// Custom exceptions for forum operations
///
/// This file contains all the custom exceptions that can be thrown during forum operations.
/// Each exception provides specific error information to help with proper error handling
/// and user feedback.

/// Base exception class for all forum-related errors
abstract class ForumException implements Exception {
  /// User-friendly error message
  final String message;

  /// Technical error details (for debugging)
  final String? details;

  /// Error code for programmatic handling
  final String? code;

  const ForumException(this.message, {this.details, this.code});

  @override
  String toString() => 'ForumException: $message';
}

/// Exception thrown when post validation fails
class PostValidationException extends ForumException {
  /// The field that failed validation
  final String field;

  /// The validation rule that was violated
  final String rule;

  const PostValidationException(
    super.message, {
    required this.field,
    required this.rule,
    super.details,
    super.code,
  });

  @override
  String toString() =>
      'PostValidationException: $message (Field: $field, Rule: $rule)';
}

/// Exception thrown when post creation fails
class PostCreationException extends ForumException {
  /// The reason for the failure
  final String reason;

  const PostCreationException(
    super.message, {
    required this.reason,
    super.details,
    super.code,
  });

  @override
  String toString() => 'PostCreationException: $message (Reason: $reason)';
}

/// Exception thrown when comment validation fails
class CommentValidationException extends ForumException {
  /// The field that failed validation
  final String field;

  /// The validation rule that was violated
  final String rule;

  const CommentValidationException(
    super.message, {
    required this.field,
    required this.rule,
    super.details,
    super.code,
  });

  @override
  String toString() =>
      'CommentValidationException: $message (Field: $field, Rule: $rule)';
}

/// Exception thrown when comment creation fails
class CommentCreationException extends ForumException {
  /// The reason for the failure
  final String reason;

  const CommentCreationException(
    super.message, {
    required this.reason,
    super.details,
    super.code,
  });

  @override
  String toString() => 'CommentCreationException: $message (Reason: $reason)';
}

/// Exception thrown when interaction operations fail
class InteractionException extends ForumException {
  /// The type of interaction that failed
  final String interactionType;

  /// The target type (post or comment)
  final String targetType;

  const InteractionException(
    super.message, {
    required this.interactionType,
    required this.targetType,
    super.details,
    super.code,
  });

  @override
  String toString() =>
      'InteractionException: $message (Type: $interactionType, Target: $targetType)';
}

/// Exception thrown when user doesn't have permission to perform action
class ForumPermissionException extends ForumException {
  /// The action that was attempted
  final String action;

  const ForumPermissionException(
    super.message, {
    required this.action,
    super.details,
    super.code,
  });

  @override
  String toString() => 'ForumPermissionException: $message (Action: $action)';
}

/// Exception thrown when content contains inappropriate material
class ContentModerationException extends ForumException {
  /// The type of inappropriate content detected
  final String contentType;

  /// The severity level of the violation
  final String severity;

  const ContentModerationException(
    super.message, {
    required this.contentType,
    required this.severity,
    super.details,
    super.code,
  });

  @override
  String toString() =>
      'ContentModerationException: $message (Type: $contentType, Severity: $severity)';
}

/// Exception thrown when rate limiting is exceeded
class RateLimitException extends ForumException {
  /// The resource being rate limited
  final String resource;

  /// When the user can try again
  final Duration retryAfter;

  const RateLimitException(
    super.message, {
    required this.resource,
    required this.retryAfter,
    super.details,
    super.code,
  });

  @override
  String toString() =>
      'RateLimitException: $message (Resource: $resource, Retry after: $retryAfter)';
}

/// Exception thrown when user is not authenticated
class ForumAuthenticationException extends ForumException {
  const ForumAuthenticationException(
    super.message, {
    super.details,
    super.code,
  });

  @override
  String toString() => 'ForumAuthenticationException: $message';
}

/// Exception thrown when network operations fail
class ForumNetworkException extends ForumException {
  /// The type of network error
  final String networkError;

  const ForumNetworkException(
    super.message, {
    required this.networkError,
    super.details,
    super.code,
  });

  @override
  String toString() =>
      'ForumNetworkException: $message (Network Error: $networkError)';
}
