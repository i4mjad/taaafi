import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:reboot_app_3/features/community/data/models/post_form_data.dart';
import 'package:reboot_app_3/features/community/data/models/comment.dart';
import 'package:reboot_app_3/features/community/data/models/comment_thread.dart';
import 'package:reboot_app_3/features/community/data/repositories/forum_repository.dart';
import 'package:reboot_app_3/features/community/domain/services/post_validation_service.dart';
import 'package:reboot_app_3/features/community/data/exceptions/forum_exceptions.dart';
import 'package:reboot_app_3/features/community/application/gender_interaction_validator.dart';
import 'package:reboot_app_3/features/community/application/attachment_image_service.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/features/community/data/models/post_attachment_data.dart';
import 'package:reboot_app_3/features/community/data/models/attachment.dart';
import '../../../account/data/app_features_config.dart';
import '../../../account/application/ban_warning_facade.dart';
import '../../../account/data/models/ban.dart';

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
//
/// } catch (PostValidationException e) {
//
/// } catch (ForumException e) {
//
/// }
/// ```
class ForumService {
  final ForumRepository _repository;
  final PostValidationService _validationService;
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final GenderInteractionValidator _genderValidator;
  final AttachmentImageService _imageService;

  /// Creates a new ForumService instance
  ///
  /// [repository] - The forum repository for data access
  /// [validationService] - The validation service for input validation
  /// [auth] - Firebase authentication instance
  /// [genderValidator] - The gender interaction validator for community rules
  ForumService(
    this._repository,
    this._validationService,
    this._auth,
    this._firestore,
    this._genderValidator,
    this._imageService,
  );

  /// Helper method to get community profile ID from user mapping
  Future<String> _getCommunityProfileId(String userUID) async {
    try {
      final snapshot = await _firestore
          .collection('communityProfiles')
          .where('userUID', isEqualTo: userUID)
          .where('isDeleted', isEqualTo: false)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        throw ForumAuthenticationException(
          'No community profile found for user',
          code: 'NO_COMMUNITY_PROFILE',
        );
      }

      final doc = snapshot.docs.first;
      final data = doc.data();

      // Double-check that the profile is not deleted
      if (data['isDeleted'] == true) {
        throw ForumAuthenticationException(
          'No active community profile found for user',
          code: 'NO_ACTIVE_COMMUNITY_PROFILE',
        );
      }

      return doc.id; // Return the document ID which is the community profile ID
    } catch (e) {
      if (e is ForumAuthenticationException) {
        rethrow;
      }
      throw ForumAuthenticationException(
        'Failed to get community profile: ${e.toString()}',
        code: 'PROFILE_LOOKUP_FAILED',
      );
    }
  }

  /// Creates a new forum post
  ///
  /// This method performs the complete post creation workflow:
  /// 1. Validates user authentication
  /// 2. Validates post data
  /// 3. Checks user permissions
  /// 4. Sanitizes data
  /// 5. Creates the post
  /// 6. Creates attachments if provided
  /// 7. Finalizes post with attachment summary
  ///
  /// [postData] - The post data to create
  /// [localizations] - Localization helper for error messages
  /// [attachmentData] - Optional attachment data (images, poll, or group invite)
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
    AppLocalizations localizations, {
    PostAttachmentsState? attachmentData,
  }) async {
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
      final authorCPId = await _getCommunityProfileId(currentUser.uid);

      // 7. Create the post
      final hasAttachments = attachmentData?.hasAttachments ?? false;

      final postId = await _repository.createPost(
        authorCPId: authorCPId,
        title: sanitizedData.title,
        content: sanitizedData.content,
        categoryId: sanitizedData.categoryId,
        attachmentUrls: sanitizedData.attachmentUrls,
        hasAttachments: hasAttachments,
      );

      // 8. Create attachments if provided
      if (hasAttachments && attachmentData != null) {
        await _createAndFinalizeAttachments(
            postId, attachmentData, authorCPId, localizations);
      }

      // 9. Log the action for analytics
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

      // 4. Validate gender-based interaction rules
      final currentUserGender = await _getCurrentUserGender();
      if (currentUserGender != null) {
        if (parentCommentId != null) {
          // Replying to a comment
          await _genderValidator.validateCanReplyToComment(
            currentUserGender: currentUserGender,
            parentCommentId: parentCommentId,
            localizations: localizations,
            applyGenderFilter: true, // Always apply for comments
          );
        } else {
          // Commenting on a post - check the post's category to determine filtering
          await _genderValidator.validateCanCommentOnPost(
            currentUserGender: currentUserGender,
            postId: postId,
            localizations: localizations,
            applyGenderFilter: await _shouldApplyGenderFilterForPost(postId),
          );
        }
      }

      // 5. Check if post exists
      await _ensurePostExists(postId, localizations);

      // 6. Check for rate limiting
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

      // 3. Validate gender-based interaction rules
      final currentUserGender = await _getCurrentUserGender();
      if (currentUserGender != null) {
        await _genderValidator.validateCanInteractWithPost(
          currentUserGender: currentUserGender,
          postId: postId,
          localizations: localizations,
          applyGenderFilter: await _shouldApplyGenderFilterForPost(postId),
        );
      }

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

      // 3. Validate gender-based interaction rules
      final currentUserGender = await _getCurrentUserGender();
      if (currentUserGender != null) {
        await _genderValidator.validateCanInteractWithComment(
          currentUserGender: currentUserGender,
          commentId: commentId,
          localizations: localizations,
          applyGenderFilter: true, // Always apply for comments
        );
      }

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

  /// Gets the current user's gender from their community profile
  ///
  /// Returns null if user doesn't have a community profile or gender is not set
  Future<String?> _getCurrentUserGender() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      // Get community profile ID from mapping
      String profileId;
      try {
        profileId = await _getCommunityProfileId(user.uid);
      } catch (e) {
        // If no community profile found, return null
        return null;
      }

      // Get the community profile document
      final doc =
          await _firestore.collection('communityProfiles').doc(profileId).get();

      if (doc.exists) {
        final data = doc.data();
        return data?['gender'] as String?;
      }
      return null;
    } catch (e) {
      // Return null on error to avoid blocking users
      return null;
    }
  }

  /// Determines if gender filtering should be applied to a specific post
  ///
  /// [postId] The ID of the post to check
  /// Returns true if gender filtering should be applied, false otherwise
  Future<bool> _shouldApplyGenderFilterForPost(String postId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('forumPosts')
          .doc(postId)
          .get();

      if (!doc.exists) return true; // Default to applying filter

      final data = doc.data();
      final category = data?['category'] as String?;
      final isPinned = data?['isPinned'] as bool? ?? false;

      return GenderInteractionValidator.shouldApplyGenderFilter(
        category: category,
        isPinned: isPinned,
      );
    } catch (e) {
      // Default to applying filter on error
      return true;
    }
  }

  /// Checks if the user has permission to create posts
  ///
  /// Throws [ForumPermissionException] if user doesn't have permission
  Future<void> _checkPostCreationPermission(
      AppLocalizations localizations) async {
    try {
      final facade = BanWarningFacade();
      final canAccess = await facade.canUserAccessFeature(
        AppFeaturesConfig.postCreation,
      );

      if (!canAccess) {
        final ban = await facade.getCurrentUserFeatureBan(
          AppFeaturesConfig.postCreation,
        );

        final banType = ban?.severity == BanSeverity.permanent
            ? 'permanently'
            : 'temporarily';

        throw ForumPermissionException(
          localizations
              .translate('post_creation_banned')
              .replaceAll('{type}', banType),
          action: 'create_post',
          code: 'POST_CREATION_BANNED',
        );
      }
    } catch (e) {
      if (e is ForumPermissionException) {
        rethrow;
      }
      // Fail-safe: allow on error
    }
  }

  /// Checks if the user has permission to create comments
  ///
  /// Throws [ForumPermissionException] if user doesn't have permission
  Future<void> _checkCommentCreationPermission(
      AppLocalizations localizations) async {
    try {
      final facade = BanWarningFacade();
      final canAccess = await facade.canUserAccessFeature(
        AppFeaturesConfig.commentCreation,
      );

      if (!canAccess) {
        final ban = await facade.getCurrentUserFeatureBan(
          AppFeaturesConfig.commentCreation,
        );

        final banType = ban?.severity == BanSeverity.permanent
            ? 'permanently'
            : 'temporarily';

        throw ForumPermissionException(
          localizations
              .translate('comment_creation_banned')
              .replaceAll('{type}', banType),
          action: 'create_comment',
          code: 'COMMENT_CREATION_BANNED',
        );
      }
    } catch (e) {
      if (e is ForumPermissionException) {
        rethrow;
      }
      // Fail-safe: allow on error
    }
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
  }

  /// Logs comment creation for analytics
  ///
  /// [postId] - The post ID the comment was added to
  /// [content] - The comment content
  Future<void> _logCommentCreation(String postId, String content) async {
    // TODO: Implement proper analytics logging
    // For now, just print for debugging
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
  }

  /// Creates attachments and finalizes the post
  ///
  /// This method handles the multi-step finalization process:
  /// 1. Create attachment subdocuments based on type
  /// 2. Build attachment summaries
  /// 3. Finalize post with summary and types
  ///
  /// [postId] - The ID of the post to attach to
  /// [attachmentData] - The attachment data to create
  /// [authorCpId] - The author's community profile ID
  /// [localizations] - Localization helper for error messages
  ///
  /// Throws [PostCreationException] if attachment creation fails
  Future<void> _createAndFinalizeAttachments(
    String postId,
    PostAttachmentsState attachmentData,
    String authorCpId,
    AppLocalizations localizations,
  ) async {
    try {
      final List<Map<String, dynamic>> attachmentsSummary = [];
      final List<String> attachmentTypes = [];

      switch (attachmentData.selectedType!) {
        case AttachmentType.image:
          await _createImageAttachments(
            postId,
            attachmentData.attachmentData as ImageAttachmentData,
            authorCpId,
            attachmentsSummary,
            attachmentTypes,
          );
          break;

        case AttachmentType.poll:
          await _createPollAttachment(
            postId,
            attachmentData.attachmentData as PollAttachmentData,
            authorCpId,
            attachmentsSummary,
            attachmentTypes,
          );
          break;

        case AttachmentType.groupInvite:
          await _createGroupInviteAttachment(
            postId,
            attachmentData.attachmentData as GroupInviteAttachmentData,
            authorCpId,
            attachmentsSummary,
            attachmentTypes,
          );
          break;
      }

      // Finalize the post with attachment summary
      await _repository.finalizePostAttachments(
        postId: postId,
        attachmentsSummary: attachmentsSummary,
        attachmentTypes: attachmentTypes,
      );
    } catch (e) {
      throw PostCreationException(
        localizations.translate('attachment_creation_failed'),
        reason: 'attachment_creation_error',
        details: e.toString(),
        code: 'ATTACHMENT_CREATION_FAILED',
      );
    }
  }

  /// Creates image attachments with Firebase Storage upload
  Future<void> _createImageAttachments(
    String postId,
    ImageAttachmentData imageData,
    String authorCpId,
    List<Map<String, dynamic>> summaryList,
    List<String> typesList,
  ) async {
    if (imageData.images.isEmpty) return;

    try {
      // Upload all images to Firebase Storage
      final uploadedImages = await _imageService.uploadImages(
        postId: postId,
        images: imageData.images,
        onProgress: (current, total, fileName) {
          // Progress tracking can be handled by UI layer
          // For now, just continue silently
        },
      );

      // Create attachment documents for each uploaded image
      for (final uploadedImage in uploadedImages) {
        final attachmentId =
            '${DateTime.now().millisecondsSinceEpoch}_${uploadedImage.id}';

        final imageAttachment = ImageAttachment(
          id: attachmentId,
          schemaVersion: '1.0',
          createdAt: DateTime.now(),
          createdByCpId: authorCpId,
          status: 'active',
          storagePath: uploadedImage.storagePath,
          downloadUrl: uploadedImage.downloadUrl,
          width: uploadedImage.width,
          height: uploadedImage.height,
          sizeBytes: uploadedImage.sizeBytes,
          thumbnailUrl: uploadedImage.thumbnailUrl,
          contentHash: uploadedImage.contentHash,
        );

        await _repository.createAttachment(
          postId: postId,
          attachmentData: imageAttachment.toFirestore(),
        );

        summaryList.add(imageAttachment.toSummary());
      }

      typesList.add('image');
    } catch (e) {
      // Clean up any temporary files on failure
      await _imageService.cleanupTempFiles(imageData.images);
      rethrow;
    }
  }

  /// Creates poll attachment
  Future<void> _createPollAttachment(
    String postId,
    PollAttachmentData pollData,
    String authorCpId,
    List<Map<String, dynamic>> summaryList,
    List<String> typesList,
  ) async {
    final attachmentId = '${DateTime.now().millisecondsSinceEpoch}_poll';

    final pollAttachment = PollAttachment(
      id: attachmentId,
      schemaVersion: '1.0',
      createdAt: DateTime.now(),
      createdByCpId: authorCpId,
      status: 'active',
      question: pollData.question,
      options: pollData.options
          .map((opt) => PollOption(id: opt.id, text: opt.text))
          .toList(),
      selectionMode: pollData.isMultiSelect ? 'multi' : 'single',
      closesAt: pollData.closesAt,
      ownerCpId: authorCpId,
      totalVotes: 0,
      optionCounts: List.filled(pollData.options.length, 0),
      isClosed: false,
    );

    await _repository.createAttachment(
      postId: postId,
      attachmentData: pollAttachment.toFirestore(),
    );

    summaryList.add(pollAttachment.toSummary());
    typesList.add('poll');
  }

  /// Creates group invite attachment
  Future<void> _createGroupInviteAttachment(
    String postId,
    GroupInviteAttachmentData inviteData,
    String authorCpId,
    List<Map<String, dynamic>> summaryList,
    List<String> typesList,
  ) async {
    final attachmentId = '${DateTime.now().millisecondsSinceEpoch}_invite';

    final groupSnapshot = GroupSnapshot(
      name: inviteData.groupName,
      gender: inviteData.groupGender,
      capacity: inviteData.groupCapacity,
      memberCount: inviteData.groupMemberCount,
      joinMethod: inviteData.joinMethod,
      plusOnly: inviteData.groupPlusOnly,
    );

    final inviteAttachment = GroupInviteAttachment(
      id: attachmentId,
      schemaVersion: '1.0',
      createdAt: DateTime.now(),
      createdByCpId: authorCpId,
      status: 'active',
      inviterCpId: authorCpId,
      groupId: inviteData.groupId,
      groupSnapshot: groupSnapshot,
      inviteJoinCode:
          'placeholder_join_code', // TODO: Get actual group join code
      expiresAt: DateTime.now().add(const Duration(days: 30)), // 30 days expiry
    );

    await _repository.createAttachment(
      postId: postId,
      attachmentData: inviteAttachment.toFirestore(),
    );

    summaryList.add(inviteAttachment.toSummary());
    typesList.add('group_invite');
  }

  /// Reply to a comment
  Future<void> replyToComment({
    required String commentId,
    required String content,
    required AppLocalizations localizations,
  }) async {
    try {
      // 1. Check authentication
      await _ensureAuthenticated();

      // 2. Validate comment content
      _validateCommentContent(content, localizations);

      // 3. Check user permissions
      await _checkCommentCreationPermission(localizations);

      // 4. Get the parent comment to determine the post ID
      final commentThread = await _repository.getCommentThread(commentId);
      final parentComment = commentThread.parentComment;

      // 5. Validate gender-based interaction rules
      final currentUserGender = await _getCurrentUserGender();
      if (currentUserGender != null) {
        await _genderValidator.validateCanReplyToComment(
          currentUserGender: currentUserGender,
          parentCommentId: commentId,
          localizations: localizations,
          applyGenderFilter: true,
        );
      }

      // 6. Check for rate limiting
      await _checkRateLimit('comment_creation', localizations);

      // 7. Create the reply
      await _repository.addComment(
        postId: parentComment.postId,
        body: content.trim(),
        parentFor: 'comment',
        parentId: commentId,
      );

      // 8. Log the action for analytics
      await _logCommentCreation(parentComment.postId, content);
    } on CommentCreationException {
      // Re-throw comment creation exceptions
      rethrow;
    } catch (e) {
      // Convert unexpected errors to CommentCreationException
      throw CommentCreationException(
        localizations.translate('reply_creation_failed'),
        reason: 'unexpected_error',
        details: e.toString(),
        code: 'REPLY_CREATION_FAILED',
      );
    }
  }

  /// Get comment thread (comment + its replies)
  Future<CommentThread> getCommentThread(String commentId) async {
    try {
      await _ensureAuthenticated();
      return await _repository.getCommentThread(commentId);
    } catch (e) {
      throw CommentCreationException(
        'Failed to load comment thread',
        reason: 'thread_loading_failed',
        details: e.toString(),
        code: 'THREAD_LOADING_FAILED',
      );
    }
  }

  /// Get nested comments for a post
  Future<Map<String, List<Comment>>> getNestedComments(String postId) async {
    try {
      await _ensureAuthenticated();
      return await _repository.getNestedComments(postId);
    } catch (e) {
      throw CommentCreationException(
        'Failed to load nested comments',
        reason: 'nested_comments_loading_failed',
        details: e.toString(),
        code: 'NESTED_COMMENTS_LOADING_FAILED',
      );
    }
  }
}
