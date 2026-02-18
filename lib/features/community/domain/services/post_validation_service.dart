import 'package:reboot_app_3/features/community/data/models/post_form_data.dart';
import 'package:reboot_app_3/features/community/data/exceptions/forum_exceptions.dart';
import 'package:reboot_app_3/core/localization/localization.dart';

/// Service responsible for validating forum post data
///
/// Currently enforces only the minimal checks required for post creation:
/// - Word count limits for the content
/// - Spam detection for both title and content
/// All other heuristics were intentionally removed to keep the experience lightweight.
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
  }

  /// Validates post title
  ///
  /// Only checks the title for spammy patterns.
  ///
  /// [title] - The title to validate
  /// [localizations] - Localization helper for error messages
  ///
  /// Throws [PostValidationException] if validation fails
  void validateTitle(String title, AppLocalizations localizations) {
    final trimmedTitle = title.trim();

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
  /// Ensures the content stays within the allowed word count range and checks
  /// for spammy patterns.
  ///
  /// [content] - The content to validate
  /// [localizations] - Localization helper for error messages
  ///
  /// Throws [PostValidationException] if validation fails
  void validateContent(String content, AppLocalizations localizations) {
    final trimmedContent = content.trim();

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
}
