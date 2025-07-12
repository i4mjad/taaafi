/// Custom exceptions for the community feature
///
/// These exceptions provide specific error types for different community operations
/// following the clean architecture pattern and making error handling more precise.

/// Base exception class for community-related errors
///
/// This serves as the parent class for all community-specific exceptions,
/// providing a consistent error handling structure across the feature.
abstract class CommunityException implements Exception {
  /// Human-readable error message
  final String message;

  /// Optional error code for programmatic handling
  final String? code;

  const CommunityException(this.message, [this.code]);

  @override
  String toString() =>
      'CommunityException: $message${code != null ? ' (Code: $code)' : ''}';
}

/// Exception thrown when profile creation fails
class ProfileCreationException extends CommunityException {
  const ProfileCreationException(super.message, [super.code]);
}

/// Exception thrown when profile is not found
class ProfileNotFoundException extends CommunityException {
  const ProfileNotFoundException(super.message, [super.code]);
}

/// Exception thrown when profile update fails
class ProfileUpdateException extends CommunityException {
  const ProfileUpdateException(super.message, [super.code]);
}

/// Exception thrown when profile deletion fails
class ProfileDeletionException extends CommunityException {
  const ProfileDeletionException(super.message, [super.code]);
}

/// Exception thrown when validation fails
class ValidationException extends CommunityException {
  const ValidationException(super.message, [super.code]);
}

/// Exception thrown when user is not authenticated
class AuthenticationException extends CommunityException {
  const AuthenticationException(super.message, [super.code]);
}

/// Exception thrown when network operations fail
class NetworkException extends CommunityException {
  const NetworkException(super.message, [super.code]);
}

/// Exception thrown when Firestore operations fail
class FirestoreException extends CommunityException {
  const FirestoreException(super.message, [super.code]);
}
