import 'package:firebase_auth/firebase_auth.dart';
import 'package:reboot_app_3/features/community/data/models/post_form_data.dart';
import 'package:reboot_app_3/features/community/data/repositories/forum_repository.dart';
import 'package:reboot_app_3/features/community/domain/services/post_validation_service.dart';
import 'package:reboot_app_3/features/community/data/exceptions/forum_exceptions.dart';
import 'package:reboot_app_3/core/localization/localization.dart';

/// Service layer for forum operations
///
/// This service implements the business logic for forum operations including
/// post creation, validation, and interaction management. It follows clean architecture
/// principles by separating business logic from data access and presentation layers.
///
/// The service provides:
/// - Post creation with validation
/// - Comment management
/// - Interaction handling (likes, votes)
/// - Permission checking
/// - Error handling with proper exceptions
///
/// Example usage:
/// ```dart
/// final forumService = ForumService(repository, validationService);
///
/// try {
///   final postId = await forumService.createPost(postData, localizations);
///   print('Post created successfully: $postId');
/// } catch (PostValidationException e) {
///   print('Validation error: ${e.message}');
/// } catch (ForumException e) {
///   print('Forum error: ${e.message}');
/// }
/// ```
class ForumService {
  final ForumRepository _repository;
  final PostValidationService _validationService;
  final FirebaseAuth _auth;

  /// Creates a new ForumService instance
  ///
  /// [repository] - The forum repository for data access
  /// [validationService] - The validation service for input validation
  /// [auth] - Firebase authentication instance
  ForumService(
    this._repository,
    this._validationService,
    this._auth,
  );

  /// Creates a new forum post
  ///
  /// This method performs the complete post creation workflow:
  /// 1. Validates user authentication
  /// 2. Validates post data
  /// 3. Checks user permissions
  /// 4. Sanitizes data
  /// 5. Creates the post
  ///
  /// [postData] - The post data to create
  /// [localizations] - Localization helper for error messages
  ///
  /// Returns the ID of the created post
  ///
  /// Throws:
  /// - [ForumAuthenticationException] if user is not authenticated
  /// - [PostValidationException] if validation fails
  /// - [ForumPermissionException] if user doesn't have permission
  /// - [PostCreationException] if post creation fails
  /// - [ForumNetworkException] if network error occurs
  Future<String> createPost(
    PostFormData postData,
    AppLocalizations localizations,
  ) async {
    try {
      // 1. Check authentication
      await _ensureAuthenticated();

      // 2. Validate post data
      _validationService.validatePostData(postData, localizations);

      // 3. Check user permissions
      await _checkPostCreationPermission(localizations);

      // 4. Sanitize data
      final sanitizedData = postData.sanitized();

      // 5. Check for rate limiting
      await _checkRateLimit('post_creation', localizations);

      // 6. Get current user's community profile ID
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw ForumAuthenticationException(
          localizations.translate('authentication_required'),
          code: 'USER_NOT_AUTHENTICATED',
        );
      }

      // Use the user's UID as the authorCPId for now
      // TODO: Replace with actual community profile ID when implemented
      final authorCPId = currentUser.uid;

      // 7. Create the post
      final postId = await _repository.createPost(
        authorCPId: authorCPId,
        title: sanitizedData.title,
        content: sanitizedData.content,
        categoryId: sanitizedData.categoryId,
        attachmentUrls: sanitizedData.attachmentUrls,
      );

      // 8. Log the action for analytics
      await _logPostCreation(postId, sanitizedData);

      return postId;
    } on ForumException {
      // Re-throw forum-specific exceptions
      rethrow;
    } catch (e) {
      // Convert unexpected errors to ForumException
      throw PostCreationException(
        localizations.translate('post_creation_failed'),
        reason: 'unexpected_error',
        details: e.toString(),
        code: 'POST_CREATION_FAILED',
      );
    }
  }

  /// Adds a comment to a post
  ///
  /// This method handles comment creation with proper validation and error handling.
  ///
  /// [postId] - The ID of the post to comment on
  /// [content] - The comment content
  /// [localizations] - Localization helper for error messages
  /// [parentCommentId] - Optional parent comment ID for replies
  ///
  /// Throws:
  /// - [ForumAuthenticationException] if user is not authenticated
  /// - [CommentValidationException] if validation fails
  /// - [ForumPermissionException] if user doesn't have permission
  /// - [CommentCreationException] if comment creation fails
  Future<void> addComment({
    required String postId,
    required String content,
    required AppLocalizations localizations,
    String? parentCommentId,
  }) async {
    try {
      // 1. Check authentication
      await _ensureAuthenticated();

      // 2. Validate comment content
      _validateCommentContent(content, localizations);

      // 3. Check user permissions
      await _checkCommentCreationPermission(localizations);

      // 4. Check if post exists
      await _ensurePostExists(postId, localizations);

      // 5. Check for rate limiting
      await _checkRateLimit('comment_creation', localizations);

      // 6. Create the comment
      await _repository.addComment(
        postId: postId,
        body: content.trim(),
        parentFor: parentCommentId != null ? 'comment' : 'post',
        parentId: parentCommentId ?? postId,
      );

      // 7. Log the action for analytics
      await _logCommentCreation(postId, content);
    } on ForumException {
      // Re-throw forum-specific exceptions
      rethrow;
    } catch (e) {
      // Convert unexpected errors to ForumException
      throw CommentCreationException(
        localizations.translate('comment_creation_failed'),
        reason: 'unexpected_error',
        details: e.toString(),
        code: 'COMMENT_CREATION_FAILED',
      );
    }
  }

  /// Interacts with a post (like/dislike)
  ///
  /// This method handles post interactions with proper validation and error handling.
  ///
  /// [postId] - The ID of the post to interact with
  /// [value] - The interaction value (1 for like, -1 for dislike, 0 for neutral)
  /// [localizations] - Localization helper for error messages
  ///
  /// Throws:
  /// - [ForumAuthenticationException] if user is not authenticated
  /// - [ForumPermissionException] if user doesn't have permission
  /// - [InteractionException] if interaction fails
  Future<void> interactWithPost({
    required String postId,
    required int value,
    required AppLocalizations localizations,
  }) async {
    try {
      // 1. Check authentication
      await _ensureAuthenticated();

      // 2. Validate interaction value
      _validateInteractionValue(value, localizations);

      // 3. Check user permissions
      await _checkVotingPermission(localizations);

      // 4. Check if post exists
      await _ensurePostExists(postId, localizations);

      // 5. Check for rate limiting
      await _checkRateLimit('interaction', localizations);

      // 6. Perform the interaction
      await _repository.interactWithPost(postId: postId, value: value);

      // 7. Log the action for analytics
      await _logInteractionAction('post', postId, value);
    } on ForumException {
      // Re-throw forum-specific exceptions
      rethrow;
    } catch (e) {
      // Convert unexpected errors to ForumException
      throw InteractionException(
        localizations.translate('interaction_failed'),
        interactionType: 'like',
        targetType: 'post',
        details: e.toString(),
        code: 'INTERACTION_FAILED',
      );
    }
  }

  /// Interacts with a comment (like/dislike)
  ///
  /// This method handles comment interactions with proper validation and error handling.
  ///
  /// [commentId] - The ID of the comment to interact with
  /// [value] - The interaction value (1 for like, -1 for dislike, 0 for neutral)
  /// [localizations] - Localization helper for error messages
  ///
  /// Throws:
  /// - [ForumAuthenticationException] if user is not authenticated
  /// - [ForumPermissionException] if user doesn't have permission
  /// - [InteractionException] if interaction fails
  Future<void> interactWithComment({
    required String commentId,
    required int value,
    required AppLocalizations localizations,
  }) async {
    try {
      // 1. Check authentication
      await _ensureAuthenticated();

      // 2. Validate interaction value
      _validateInteractionValue(value, localizations);

      // 3. Check user permissions
      await _checkVotingPermission(localizations);

      // 4. Check if comment exists
      await _ensureCommentExists(commentId, localizations);

      // 5. Check for rate limiting
      await _checkRateLimit('interaction', localizations);

      // 6. Perform the interaction
      await _repository.interactWithComment(commentId: commentId, value: value);

      // 7. Log the action for analytics
      await _logInteractionAction('comment', commentId, value);
    } on ForumException {
      // Re-throw forum-specific exceptions
      rethrow;
    } catch (e) {
      // Convert unexpected errors to ForumException
      throw InteractionException(
        localizations.translate('interaction_failed'),
        interactionType: 'like',
        targetType: 'comment',
        details: e.toString(),
        code: 'INTERACTION_FAILED',
      );
    }
  }

  /// Legacy method for backward compatibility
  @deprecated
  Future<void> voteOnPost({
    required String postId,
    required int value,
    required AppLocalizations localizations,
  }) async {
    return interactWithPost(
      postId: postId,
      value: value,
      localizations: localizations,
    );
  }

  /// Legacy method for backward compatibility
  @deprecated
  Future<void> voteOnComment({
    required String commentId,
    required int value,
    required AppLocalizations localizations,
  }) async {
    return interactWithComment(
      commentId: commentId,
      value: value,
      localizations: localizations,
    );
  }

  /// Validates comment content
  ///
  /// [content] - The comment content to validate
  /// [localizations] - Localization helper for error messages
  ///
  /// Throws [CommentValidationException] if validation fails
  void _validateCommentContent(String content, AppLocalizations localizations) {
    final trimmedContent = content.trim();

    if (trimmedContent.isEmpty) {
      throw CommentValidationException(
        localizations.translate('comment_empty'),
        field: 'content',
        rule: 'required',
        code: 'COMMENT_EMPTY',
      );
    }

    if (trimmedContent.length < 3) {
      throw CommentValidationException(
        localizations.translate('comment_too_short'),
        field: 'content',
        rule: 'minLength',
        code: 'COMMENT_TOO_SHORT',
        details: 'Minimum length: 3 characters',
      );
    }

    if (trimmedContent.length > 1000) {
      throw CommentValidationException(
        localizations.translate('comment_too_long'),
        field: 'content',
        rule: 'maxLength',
        code: 'COMMENT_TOO_LONG',
        details: 'Maximum length: 1000 characters',
      );
    }
  }

  /// Validates interaction value
  ///
  /// [value] - The interaction value to validate
  /// [localizations] - Localization helper for error messages
  ///
  /// Throws [InteractionException] if validation fails
  void _validateInteractionValue(int value, AppLocalizations localizations) {
    if (value < -1 || value > 1) {
      throw InteractionException(
        localizations.translate('invalid_interaction_value'),
        interactionType: 'like',
        targetType: 'unknown',
        code: 'INVALID_INTERACTION_VALUE',
      );
    }
  }

  /// Ensures the user is authenticated
  ///
  /// Throws [ForumAuthenticationException] if user is not authenticated
  Future<void> _ensureAuthenticated() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const ForumAuthenticationException(
        'User must be authenticated to perform this action',
        code: 'NOT_AUTHENTICATED',
      );
    }
  }

  /// Checks if the user has permission to create posts
  ///
  /// Throws [ForumPermissionException] if user doesn't have permission
  Future<void> _checkPostCreationPermission(
      AppLocalizations localizations) async {
    // TODO: Implement proper permission checking
    // For now, all authenticated users can create posts
    // In the future, this should check user roles, bans, etc.

    // Example implementation:
    // final user = _auth.currentUser!;
    // final permissions = await _permissionService.getUserPermissions(user.uid);
    // if (!permissions.canCreatePosts) {
    //   throw ForumPermissionException(
    //     localizations.translate('no_post_creation_permission'),
    //     action: 'create_post',
    //     code: 'NO_POST_CREATION_PERMISSION',
    //   );
    // }
  }

  /// Checks if the user has permission to create comments
  ///
  /// Throws [ForumPermissionException] if user doesn't have permission
  Future<void> _checkCommentCreationPermission(
      AppLocalizations localizations) async {
    // TODO: Implement proper permission checking
    // For now, all authenticated users can create comments
  }

  /// Checks if the user has permission to vote
  ///
  /// Throws [ForumPermissionException] if user doesn't have permission
  Future<void> _checkVotingPermission(AppLocalizations localizations) async {
    // TODO: Implement proper permission checking
    // For now, all authenticated users can vote
  }

  /// Checks rate limiting for the specified resource
  ///
  /// [resource] - The resource being accessed
  /// [localizations] - Localization helper for error messages
  ///
  /// Throws [RateLimitException] if rate limit is exceeded
  Future<void> _checkRateLimit(
      String resource, AppLocalizations localizations) async {
    // TODO: Implement proper rate limiting
    // For now, no rate limiting is applied

    // Example implementation:
    // final user = _auth.currentUser!;
    // final rateLimitInfo = await _rateLimitService.checkRateLimit(user.uid, resource);
    // if (rateLimitInfo.isExceeded) {
    //   throw RateLimitException(
    //     localizations.translate('rate_limit_exceeded'),
    //     resource: resource,
    //     retryAfter: rateLimitInfo.retryAfter,
    //     code: 'RATE_LIMIT_EXCEEDED',
    //   );
    // }
  }

  /// Ensures that a post exists
  ///
  /// [postId] - The post ID to check
  /// [localizations] - Localization helper for error messages
  ///
  /// Throws [PostCreationException] if post doesn't exist
  Future<void> _ensurePostExists(
      String postId, AppLocalizations localizations) async {
    // TODO: Implement proper post existence checking
    // For now, assume all posts exist

    // Example implementation:
    // final post = await _repository.getPost(postId);
    // if (post == null) {
    //   throw PostCreationException(
    //     localizations.translate('post_not_found'),
    //     reason: 'post_not_found',
    //     code: 'POST_NOT_FOUND',
    //   );
    // }
  }

  /// Ensures that a comment exists
  ///
  /// [commentId] - The comment ID to check
  /// [localizations] - Localization helper for error messages
  ///
  /// Throws [CommentCreationException] if comment doesn't exist
  Future<void> _ensureCommentExists(
      String commentId, AppLocalizations localizations) async {
    // TODO: Implement proper comment existence checking
    // For now, assume all comments exist
  }

  /// Logs post creation for analytics
  ///
  /// [postId] - The created post ID
  /// [postData] - The post data
  Future<void> _logPostCreation(String postId, PostFormData postData) async {
    // TODO: Implement proper analytics logging
    // For now, just print for debugging
    print('Post created: $postId, category: ${postData.categoryId}');
  }

  /// Logs comment creation for analytics
  ///
  /// [postId] - The post ID the comment was added to
  /// [content] - The comment content
  Future<void> _logCommentCreation(String postId, String content) async {
    // TODO: Implement proper analytics logging
    // For now, just print for debugging
    print('Comment created on post: $postId, length: ${content.length}');
  }

  /// Logs interaction action for analytics
  ///
  /// [targetType] - The type of target (post or comment)
  /// [targetId] - The target ID
  /// [value] - The interaction value
  Future<void> _logInteractionAction(
      String targetType, String targetId, int value) async {
    // TODO: Implement proper analytics logging
    // For now, just print for debugging
    String action = value == 1
        ? 'like'
        : value == -1
            ? 'dislike'
            : 'neutral';
    print('Interaction: $action on $targetType: $targetId');
  }
}
