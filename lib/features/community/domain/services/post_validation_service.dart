import 'package:reboot_app_3/features/community/data/models/post_form_data.dart';
import 'package:reboot_app_3/features/community/data/exceptions/forum_exceptions.dart';
import 'package:reboot_app_3/core/localization/localization.dart';

/// Service responsible for validating forum post data
///
/// This service provides comprehensive validation for post creation and editing.
/// It follows the Single Responsibility Principle by focusing solely on validation logic.
/// All validation rules are centralized here to ensure consistency and maintainability.
///
/// Example usage:
/// ```dart
/// final validator = PostValidationService();
/// final postData = PostFormData(title: 'My Title', content: 'Content...');
///
/// try {
///   validator.validatePostData(postData, localizations);
///   // Data is valid, proceed with post creation
/// } catch (PostValidationException e) {
///   // Handle validation error
///   print('Validation failed: ${e.message}');
/// }
/// ```
class PostValidationService {
  /// Validates complete post form data
  ///
  /// Performs all validation checks on the provided post data.
  /// Throws [PostValidationException] if any validation fails.
  ///
  /// [postData] - The post data to validate
  /// [localizations] - Localization helper for error messages
  ///
  /// Throws:
  /// - [PostValidationException] if validation fails
  /// - [ArgumentError] if postData is null
  void validatePostData(PostFormData postData, AppLocalizations localizations) {
    if (postData == null) {
      throw ArgumentError('Post data cannot be null');
    }

    // Validate title
    validateTitle(postData.title, localizations);

    // Validate content
    validateContent(postData.content, localizations);

    // Validate category
    validateCategory(postData.categoryId, localizations);

    // Validate attachments (if any)
    if (postData.hasAttachments) {
      validateAttachments(postData.attachmentUrls, localizations);
    }

    // Validate tags (if any)
    if (postData.hasTags) {
      validateTags(postData.tags, localizations);
    }

    // Validate combined constraints
    validateCombinedConstraints(postData, localizations);
  }

  /// Validates post title
  ///
  /// Checks title length, content, and format requirements.
  ///
  /// [title] - The title to validate
  /// [localizations] - Localization helper for error messages
  ///
  /// Throws [PostValidationException] if validation fails
  void validateTitle(String title, AppLocalizations localizations) {
    final trimmedTitle = title.trim();

    // Check if title is empty
    if (trimmedTitle.isEmpty) {
      throw PostValidationException(
        localizations.translate('post_title_empty'),
        field: 'title',
        rule: 'required',
        code: 'TITLE_EMPTY',
      );
    }

    // Check minimum length
    if (trimmedTitle.length < PostFormValidationConstants.minTitleLength) {
      throw PostValidationException(
        localizations.translate('post_title_too_short'),
        field: 'title',
        rule: 'minLength',
        code: 'TITLE_TOO_SHORT',
        details:
            'Minimum length: ${PostFormValidationConstants.minTitleLength}',
      );
    }

    // Check maximum length
    if (trimmedTitle.length > PostFormValidationConstants.maxTitleLength) {
      throw PostValidationException(
        localizations.translate('post_title_too_long'),
        field: 'title',
        rule: 'maxLength',
        code: 'TITLE_TOO_LONG',
        details:
            'Maximum length: ${PostFormValidationConstants.maxTitleLength}',
      );
    }

    // Check for inappropriate content
    if (_containsInappropriateContent(trimmedTitle)) {
      throw PostValidationException(
        localizations.translate('post_title_inappropriate'),
        field: 'title',
        rule: 'contentFilter',
        code: 'TITLE_INAPPROPRIATE',
      );
    }

    // Check for spammy patterns
    if (_containsSpammyPatterns(trimmedTitle)) {
      throw PostValidationException(
        localizations.translate('post_title_spammy'),
        field: 'title',
        rule: 'spamFilter',
        code: 'TITLE_SPAMMY',
      );
    }
  }

  /// Validates post content
  ///
  /// Checks content length, quality, and format requirements.
  ///
  /// [content] - The content to validate
  /// [localizations] - Localization helper for error messages
  ///
  /// Throws [PostValidationException] if validation fails
  void validateContent(String content, AppLocalizations localizations) {
    final trimmedContent = content.trim();

    // Check if content is empty
    if (trimmedContent.isEmpty) {
      throw PostValidationException(
        localizations.translate('post_content_empty'),
        field: 'content',
        rule: 'required',
        code: 'CONTENT_EMPTY',
      );
    }

    // Check minimum length
    if (trimmedContent.length < PostFormValidationConstants.minContentLength) {
      throw PostValidationException(
        localizations.translate('post_content_too_short'),
        field: 'content',
        rule: 'minLength',
        code: 'CONTENT_TOO_SHORT',
        details:
            'Minimum length: ${PostFormValidationConstants.minContentLength}',
      );
    }

    // Check maximum length
    if (trimmedContent.length > PostFormValidationConstants.maxContentLength) {
      throw PostValidationException(
        localizations.translate('post_content_too_long'),
        field: 'content',
        rule: 'maxLength',
        code: 'CONTENT_TOO_LONG',
        details:
            'Maximum length: ${PostFormValidationConstants.maxContentLength}',
      );
    }

    // Check word count
    final wordCount = trimmedContent
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .length;
    if (wordCount < PostFormValidationConstants.minContentWordCount) {
      throw PostValidationException(
        localizations.translate('post_content_too_few_words'),
        field: 'content',
        rule: 'minWordCount',
        code: 'CONTENT_TOO_FEW_WORDS',
        details:
            'Minimum words: ${PostFormValidationConstants.minContentWordCount}',
      );
    }

    if (wordCount > PostFormValidationConstants.maxContentWordCount) {
      throw PostValidationException(
        localizations.translate('post_content_too_many_words'),
        field: 'content',
        rule: 'maxWordCount',
        code: 'CONTENT_TOO_MANY_WORDS',
        details:
            'Maximum words: ${PostFormValidationConstants.maxContentWordCount}',
      );
    }

    // Check for inappropriate content
    if (_containsInappropriateContent(trimmedContent)) {
      throw PostValidationException(
        localizations.translate('post_content_inappropriate'),
        field: 'content',
        rule: 'contentFilter',
        code: 'CONTENT_INAPPROPRIATE',
      );
    }

    // Check for spammy patterns
    if (_containsSpammyPatterns(trimmedContent)) {
      throw PostValidationException(
        localizations.translate('post_content_spammy'),
        field: 'content',
        rule: 'spamFilter',
        code: 'CONTENT_SPAMMY',
      );
    }
  }

  /// Validates post category
  ///
  /// Checks if the category is valid and allowed.
  ///
  /// [categoryId] - The category ID to validate
  /// [localizations] - Localization helper for error messages
  ///
  /// Throws [PostValidationException] if validation fails
  void validateCategory(String? categoryId, AppLocalizations localizations) {
    // Category is optional, default to 'general' if not provided
    final effectiveCategory = categoryId ?? 'general';

    // Check if category is valid (basic validation)
    if (effectiveCategory.isEmpty) {
      throw PostValidationException(
        localizations.translate('post_category_invalid'),
        field: 'categoryId',
        rule: 'required',
        code: 'CATEGORY_INVALID',
      );
    }

    // Check category format (alphanumeric and underscore only)
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(effectiveCategory)) {
      throw PostValidationException(
        localizations.translate('post_category_invalid_format'),
        field: 'categoryId',
        rule: 'format',
        code: 'CATEGORY_INVALID_FORMAT',
      );
    }
  }

  /// Validates post attachments
  ///
  /// Checks attachment count and format.
  ///
  /// [attachmentUrls] - List of attachment URLs to validate
  /// [localizations] - Localization helper for error messages
  ///
  /// Throws [PostValidationException] if validation fails
  void validateAttachments(
      List<String> attachmentUrls, AppLocalizations localizations) {
    // Check attachment count
    if (attachmentUrls.length > PostFormValidationConstants.maxAttachments) {
      throw PostValidationException(
        localizations.translate('post_attachments_too_many'),
        field: 'attachmentUrls',
        rule: 'maxCount',
        code: 'ATTACHMENTS_TOO_MANY',
        details:
            'Maximum attachments: ${PostFormValidationConstants.maxAttachments}',
      );
    }

    // Validate each attachment URL
    for (int i = 0; i < attachmentUrls.length; i++) {
      final url = attachmentUrls[i].trim();

      if (url.isEmpty) {
        throw PostValidationException(
          localizations.translate('post_attachment_empty'),
          field: 'attachmentUrls[$i]',
          rule: 'required',
          code: 'ATTACHMENT_EMPTY',
        );
      }

      // Basic URL validation
      final uri = Uri.tryParse(url);
      if (uri == null || !uri.hasAbsolutePath) {
        throw PostValidationException(
          localizations.translate('post_attachment_invalid_url'),
          field: 'attachmentUrls[$i]',
          rule: 'format',
          code: 'ATTACHMENT_INVALID_URL',
        );
      }
    }
  }

  /// Validates post tags
  ///
  /// Checks tag count, length, and format.
  ///
  /// [tags] - List of tags to validate
  /// [localizations] - Localization helper for error messages
  ///
  /// Throws [PostValidationException] if validation fails
  void validateTags(List<String> tags, AppLocalizations localizations) {
    // Check tag count
    if (tags.length > PostFormValidationConstants.maxTags) {
      throw PostValidationException(
        localizations.translate('post_tags_too_many'),
        field: 'tags',
        rule: 'maxCount',
        code: 'TAGS_TOO_MANY',
        details: 'Maximum tags: ${PostFormValidationConstants.maxTags}',
      );
    }

    // Validate each tag
    for (int i = 0; i < tags.length; i++) {
      final tag = tags[i].trim();

      if (tag.isEmpty) {
        throw PostValidationException(
          localizations.translate('post_tag_empty'),
          field: 'tags[$i]',
          rule: 'required',
          code: 'TAG_EMPTY',
        );
      }

      if (tag.length > PostFormValidationConstants.maxTagLength) {
        throw PostValidationException(
          localizations.translate('post_tag_too_long'),
          field: 'tags[$i]',
          rule: 'maxLength',
          code: 'TAG_TOO_LONG',
          details:
              'Maximum tag length: ${PostFormValidationConstants.maxTagLength}',
        );
      }

      // Check tag format (alphanumeric, underscore, and hyphen only)
      if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(tag)) {
        throw PostValidationException(
          localizations.translate('post_tag_invalid_format'),
          field: 'tags[$i]',
          rule: 'format',
          code: 'TAG_INVALID_FORMAT',
        );
      }
    }
  }

  /// Validates combined constraints
  ///
  /// Checks constraints that depend on multiple fields.
  ///
  /// [postData] - The complete post data
  /// [localizations] - Localization helper for error messages
  ///
  /// Throws [PostValidationException] if validation fails
  void validateCombinedConstraints(
      PostFormData postData, AppLocalizations localizations) {
    // Check if the post is too short overall
    final totalLength =
        postData.trimmedTitle.length + postData.trimmedContent.length;
    if (totalLength < 10) {
      throw PostValidationException(
        localizations.translate('post_too_short_overall'),
        field: 'combined',
        rule: 'minTotalLength',
        code: 'POST_TOO_SHORT_OVERALL',
      );
    }

    // Check if title and content are too similar
    if (_areTooSimilar(postData.trimmedTitle, postData.trimmedContent)) {
      throw PostValidationException(
        localizations.translate('post_title_content_too_similar'),
        field: 'combined',
        rule: 'similarity',
        code: 'TITLE_CONTENT_TOO_SIMILAR',
      );
    }
  }

  /// Checks if text contains inappropriate content
  ///
  /// This is a basic implementation that should be replaced with a proper
  /// content moderation service in production.
  ///
  /// [text] - The text to check
  ///
  /// Returns true if inappropriate content is detected
  bool _containsInappropriateContent(String text) {
    // Basic inappropriate content detection
    final inappropriateWords = [
      // This is a very basic list - in production, use a proper content moderation service
      'spam', 'scam', 'fraud', 'hack', 'cheat',
    ];

    final lowercaseText = text.toLowerCase();
    return inappropriateWords.any((word) => lowercaseText.contains(word));
  }

  /// Checks if text contains spammy patterns
  ///
  /// Detects common spam patterns like excessive repetition, all caps, etc.
  ///
  /// [text] - The text to check
  ///
  /// Returns true if spammy patterns are detected
  bool _containsSpammyPatterns(String text) {
    // Check for excessive repetition of characters
    if (RegExp(r'(.)\1{4,}').hasMatch(text)) {
      return true;
    }

    // Check for excessive caps (more than 70% uppercase)
    final upperCaseCount = text.replaceAll(RegExp(r'[^A-Z]'), '').length;
    final letterCount = text.replaceAll(RegExp(r'[^A-Za-z]'), '').length;
    if (letterCount > 0 && (upperCaseCount / letterCount) > 0.7) {
      return true;
    }

    // Check for excessive punctuation
    final punctuationCount = text.replaceAll(RegExp(r'[^!?.]'), '').length;
    if (punctuationCount > text.length * 0.2) {
      return true;
    }

    return false;
  }

  /// Checks if two strings are too similar
  ///
  /// Uses a simple similarity check based on common words.
  ///
  /// [text1] - First text to compare
  /// [text2] - Second text to compare
  ///
  /// Returns true if the texts are too similar
  bool _areTooSimilar(String text1, String text2) {
    if (text1.isEmpty || text2.isEmpty) return false;

    final words1 = text1.toLowerCase().split(RegExp(r'\s+'));
    final words2 = text2.toLowerCase().split(RegExp(r'\s+'));

    // If one text is contained in the other, they're too similar
    if (text1.toLowerCase().contains(text2.toLowerCase()) ||
        text2.toLowerCase().contains(text1.toLowerCase())) {
      return true;
    }

    // Count common words
    final commonWords = words1.where((word) => words2.contains(word)).length;
    final totalWords = words1.length + words2.length;

    // If more than 80% of words are common, they're too similar
    return (commonWords * 2.0 / totalWords) > 0.8;
  }
}
