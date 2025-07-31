import 'package:cloud_firestore/cloud_firestore.dart';
import 'gender_filtering_service.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import '../data/exceptions/forum_exceptions.dart';

/// Service for validating gender-based interactions in the community
///
/// This service ensures that users can only interact (comment, like, etc.)
/// with content from users of the same gender or from admin users.
///
/// The validation rules are:
/// - Users can interact with content from same gender users
/// - Users can interact with content from admin users (regardless of gender)
/// - Admin posts/comments are visible and interactable by all users
/// - Gender filtering does not apply to pinned posts, news, or challenges
class GenderInteractionValidator {
  final GenderFilteringService _genderFilteringService;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  GenderInteractionValidator(this._genderFilteringService);

  /// Validates if the current user can comment on a specific post
  ///
  /// [currentUserGender] The current user's gender ('male' or 'female')
  /// [postId] The ID of the post to comment on
  /// [localizations] Localization helper for error messages
  /// [applyGenderFilter] Whether to apply gender filtering (false for pinned, news, challenges)
  ///
  /// Throws [ForumPermissionException] if interaction is not allowed
  Future<void> validateCanCommentOnPost({
    required String currentUserGender,
    required String postId,
    required AppLocalizations localizations,
    bool applyGenderFilter = true,
  }) async {
    if (!applyGenderFilter) {
      // No gender validation needed for unfiltered content
      return;
    }

    try {
      // Get the post to find the author
      final postDoc =
          await _firestore.collection('forumPosts').doc(postId).get();

      if (!postDoc.exists) {
        throw ForumPermissionException(
          localizations.translate('post_not_found'),
          action: 'comment',
          code: 'POST_NOT_FOUND',
        );
      }

      final authorCPId = postDoc.data()?['authorCPId'] as String?;

      if (authorCPId == null) {
        throw ForumPermissionException(
          localizations.translate('invalid_post_data'),
          action: 'comment',
          code: 'INVALID_POST_DATA',
        );
      }

      // Validate interaction with the post author
      await _validateInteractionWithUser(
        currentUserGender: currentUserGender,
        targetAuthorCPId: authorCPId,
        action: 'comment',
        localizations: localizations,
      );
    } catch (e) {
      if (e is ForumPermissionException) {
        rethrow;
      }
      throw ForumPermissionException(
        localizations.translate('interaction_validation_failed'),
        action: 'comment',
        code: 'VALIDATION_FAILED',
        details: e.toString(),
      );
    }
  }

  /// Validates if the current user can interact with (like/dislike) a specific post
  ///
  /// [currentUserGender] The current user's gender
  /// [postId] The ID of the post to interact with
  /// [localizations] Localization helper for error messages
  /// [applyGenderFilter] Whether to apply gender filtering
  ///
  /// Throws [ForumPermissionException] if interaction is not allowed
  Future<void> validateCanInteractWithPost({
    required String currentUserGender,
    required String postId,
    required AppLocalizations localizations,
    bool applyGenderFilter = true,
  }) async {
    if (!applyGenderFilter) {
      return;
    }

    try {
      final postDoc =
          await _firestore.collection('forumPosts').doc(postId).get();

      if (!postDoc.exists) {
        throw ForumPermissionException(
          localizations.translate('post_not_found'),
          action: 'interact',
          code: 'POST_NOT_FOUND',
        );
      }

      final authorCPId = postDoc.data()?['authorCPId'] as String?;

      if (authorCPId == null) {
        throw ForumPermissionException(
          localizations.translate('invalid_post_data'),
          action: 'interact',
          code: 'INVALID_POST_DATA',
        );
      }

      await _validateInteractionWithUser(
        currentUserGender: currentUserGender,
        targetAuthorCPId: authorCPId,
        action: 'interact',
        localizations: localizations,
      );
    } catch (e) {
      if (e is ForumPermissionException) {
        rethrow;
      }
      throw ForumPermissionException(
        localizations.translate('interaction_validation_failed'),
        action: 'interact',
        code: 'VALIDATION_FAILED',
        details: e.toString(),
      );
    }
  }

  /// Validates if the current user can interact with (like/dislike) a specific comment
  ///
  /// [currentUserGender] The current user's gender
  /// [commentId] The ID of the comment to interact with
  /// [localizations] Localization helper for error messages
  /// [applyGenderFilter] Whether to apply gender filtering
  ///
  /// Throws [ForumPermissionException] if interaction is not allowed
  Future<void> validateCanInteractWithComment({
    required String currentUserGender,
    required String commentId,
    required AppLocalizations localizations,
    bool applyGenderFilter = true,
  }) async {
    if (!applyGenderFilter) {
      return;
    }

    try {
      final commentDoc =
          await _firestore.collection('comments').doc(commentId).get();

      if (!commentDoc.exists) {
        throw ForumPermissionException(
          localizations.translate('comment_not_found'),
          action: 'interact',
          code: 'COMMENT_NOT_FOUND',
        );
      }

      final authorCPId = commentDoc.data()?['authorCPId'] as String?;

      if (authorCPId == null) {
        throw ForumPermissionException(
          localizations.translate('invalid_comment_data'),
          action: 'interact',
          code: 'INVALID_COMMENT_DATA',
        );
      }

      await _validateInteractionWithUser(
        currentUserGender: currentUserGender,
        targetAuthorCPId: authorCPId,
        action: 'interact',
        localizations: localizations,
      );
    } catch (e) {
      if (e is ForumPermissionException) {
        rethrow;
      }
      throw ForumPermissionException(
        localizations.translate('interaction_validation_failed'),
        action: 'interact',
        code: 'VALIDATION_FAILED',
        details: e.toString(),
      );
    }
  }

  /// Validates if a user can reply to a specific comment
  ///
  /// [currentUserGender] The current user's gender
  /// [parentCommentId] The ID of the comment to reply to
  /// [localizations] Localization helper for error messages
  /// [applyGenderFilter] Whether to apply gender filtering
  ///
  /// Throws [ForumPermissionException] if interaction is not allowed
  Future<void> validateCanReplyToComment({
    required String currentUserGender,
    required String parentCommentId,
    required AppLocalizations localizations,
    bool applyGenderFilter = true,
  }) async {
    if (!applyGenderFilter) {
      return;
    }

    try {
      final commentDoc =
          await _firestore.collection('comments').doc(parentCommentId).get();

      if (!commentDoc.exists) {
        throw ForumPermissionException(
          localizations.translate('comment_not_found'),
          action: 'reply',
          code: 'COMMENT_NOT_FOUND',
        );
      }

      final authorCPId = commentDoc.data()?['authorCPId'] as String?;

      if (authorCPId == null) {
        throw ForumPermissionException(
          localizations.translate('invalid_comment_data'),
          action: 'reply',
          code: 'INVALID_COMMENT_DATA',
        );
      }

      await _validateInteractionWithUser(
        currentUserGender: currentUserGender,
        targetAuthorCPId: authorCPId,
        action: 'reply',
        localizations: localizations,
      );
    } catch (e) {
      if (e is ForumPermissionException) {
        rethrow;
      }
      throw ForumPermissionException(
        localizations.translate('interaction_validation_failed'),
        action: 'reply',
        code: 'VALIDATION_FAILED',
        details: e.toString(),
      );
    }
  }

  /// Core validation logic for user interactions
  ///
  /// [currentUserGender] The current user's gender
  /// [targetAuthorCPId] The community profile ID of the target content author
  /// [action] The action being attempted (for error messages)
  /// [localizations] Localization helper for error messages
  ///
  /// Throws [ForumPermissionException] if interaction is not allowed
  Future<void> _validateInteractionWithUser({
    required String currentUserGender,
    required String targetAuthorCPId,
    required String action,
    required AppLocalizations localizations,
  }) async {
    // Check if the target author is in the list of users the current user can interact with
    final canInteract = await _genderFilteringService.canInteractWithContent(
      currentUserGender,
      targetAuthorCPId,
    );

    if (!canInteract) {
      throw ForumPermissionException(
        localizations.translate('gender_interaction_not_allowed'),
        action: action,
        code: 'GENDER_INTERACTION_FORBIDDEN',
        details:
            'User cannot interact with content from different gender users',
      );
    }
  }

  /// Helper method to determine if gender filtering should be applied based on content type
  ///
  /// [category] The post category (optional)
  /// [isPinned] Whether the post is pinned (optional)
  ///
  /// Returns true if gender filtering should be applied, false otherwise
  static bool shouldApplyGenderFilter({
    String? category,
    bool? isPinned,
  }) {
    // Don't apply gender filtering to:
    // - Pinned posts
    // - News posts
    // - Challenge posts (if category is 'challenges')
    if (isPinned == true) {
      return false;
    }

    if (category != null) {
      switch (category.toLowerCase()) {
        case 'news':
        case 'challenges':
        case 'pinned':
          return false;
        default:
          return true;
      }
    }

    // Default to applying gender filter for regular posts
    return true;
  }

  /// Batch validation for multiple interactions
  ///
  /// This method can be used to validate multiple interactions at once
  /// for better performance when needed.
  ///
  /// [currentUserGender] The current user's gender
  /// [targetAuthorCPIds] List of community profile IDs to validate
  /// [action] The action being attempted
  /// [localizations] Localization helper for error messages
  ///
  /// Returns a map of authorCPId -> canInteract boolean
  Future<Map<String, bool>> validateMultipleInteractions({
    required String currentUserGender,
    required List<String> targetAuthorCPIds,
    required String action,
    required AppLocalizations localizations,
  }) async {
    try {
      final visibleProfileIds = await _genderFilteringService
          .getVisibleCommunityProfileIds(currentUserGender);

      final results = <String, bool>{};

      for (final cpId in targetAuthorCPIds) {
        results[cpId] = visibleProfileIds.contains(cpId);
      }

      return results;
    } catch (e) {
      // On error, default to allowing all interactions to avoid blocking users
      final results = <String, bool>{};
      for (final cpId in targetAuthorCPIds) {
        results[cpId] = true;
      }
      return results;
    }
  }
}
