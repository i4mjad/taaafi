import 'package:cloud_firestore/cloud_firestore.dart';

/// Data transfer object for post creation form
///
/// This model encapsulates all the data needed to create a new forum post.
/// It provides immutable data structure with validation-friendly properties.
///
/// Example usage:
/// ```dart
/// final postData = PostFormData(
///   title: 'My Post Title',
///   content: 'This is the post content...',
///   categoryId: 'discussion',
/// );
/// ```
class PostFormData {
  /// The post title
  final String title;

  /// The post content/body
  final String content;

  /// The category ID for the post
  final String? categoryId;

  /// List of attachment URLs (for future implementation)
  final List<String> attachmentUrls;

  /// List of tags (for future implementation)
  final List<String> tags;

  /// Creates a new post form data instance
  ///
  /// [title] - The post title (required, 1-300 characters)
  /// [content] - The post content (required, 1-5000 characters)
  /// [categoryId] - The category ID (optional, defaults to 'general')
  /// [attachmentUrls] - List of attachment URLs (optional, for future use)
  /// [tags] - List of tags (optional, for future use)
  const PostFormData({
    required this.title,
    required this.content,
    this.categoryId,
    this.attachmentUrls = const [],
    this.tags = const [],
  });

  /// Creates a copy with updated values
  PostFormData copyWith({
    String? title,
    String? content,
    String? categoryId,
    List<String>? attachmentUrls,
    List<String>? tags,
  }) {
    return PostFormData(
      title: title ?? this.title,
      content: content ?? this.content,
      categoryId: categoryId ?? this.categoryId,
      attachmentUrls: attachmentUrls ?? this.attachmentUrls,
      tags: tags ?? this.tags,
    );
  }

  /// Creates a PostFormData instance from JSON
  factory PostFormData.fromJson(Map<String, dynamic> json) {
    return PostFormData(
      title: json['title'] as String,
      content: json['content'] as String,
      categoryId: json['categoryId'] as String?,
      attachmentUrls: (json['attachmentUrls'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              [],
    );
  }

  /// Converts to JSON
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
      'categoryId': categoryId,
      'attachmentUrls': attachmentUrls,
      'tags': tags,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PostFormData &&
        other.title == title &&
        other.content == content &&
        other.categoryId == categoryId &&
        _listEquals(other.attachmentUrls, attachmentUrls) &&
        _listEquals(other.tags, tags);
  }

  @override
  int get hashCode {
    return title.hashCode ^
        content.hashCode ^
        categoryId.hashCode ^
        attachmentUrls.hashCode ^
        tags.hashCode;
  }

  @override
  String toString() {
    return 'PostFormData(title: $title, content: ${content.length} chars, categoryId: $categoryId, attachments: ${attachmentUrls.length}, tags: ${tags.length})';
  }

  /// Helper method to compare lists
  bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (int index = 0; index < a.length; index += 1) {
      if (a[index] != b[index]) return false;
    }
    return true;
  }
}

/// Extension methods for PostFormData validation and utility functions
extension PostFormDataExtensions on PostFormData {
  /// Returns the trimmed title
  String get trimmedTitle => title.trim();

  /// Returns the trimmed content
  String get trimmedContent => content.trim();

  /// Returns the effective category ID (with fallback to 'general')
  String get effectiveCategoryId => categoryId ?? 'general';

  /// Checks if the form data has valid basic structure
  bool get hasBasicStructure =>
      trimmedTitle.isNotEmpty && trimmedContent.isNotEmpty;

  /// Returns the word count of the content
  int get contentWordCount => trimmedContent
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .length;

  /// Returns the character count of the title
  int get titleCharacterCount => trimmedTitle.length;

  /// Returns the character count of the content
  int get contentCharacterCount => trimmedContent.length;

  /// Checks if the post has any attachments
  bool get hasAttachments => attachmentUrls.isNotEmpty;

  /// Checks if the post has any tags
  bool get hasTags => tags.isNotEmpty;

  /// Creates a copy with sanitized data (trimmed strings, normalized values)
  PostFormData sanitized() => copyWith(
        title: trimmedTitle,
        content: trimmedContent,
        categoryId: effectiveCategoryId,
        attachmentUrls:
            attachmentUrls.where((url) => url.trim().isNotEmpty).toList(),
        tags: tags.where((tag) => tag.trim().isNotEmpty).toList(),
      );

  /// Converts to a map suitable for Firestore storage
  Map<String, dynamic> toFirestoreMap() => {
        'title': trimmedTitle,
        'content': trimmedContent,
        'categoryId': effectiveCategoryId,
        'attachmentUrls': attachmentUrls,
        'tags': tags,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'score': 0,
      };
}

/// Validation constants for post form data
class PostFormValidationConstants {
  /// Minimum title length
  static const int minTitleLength = 7;

  /// Maximum title length
  static const int maxTitleLength = 80;

  /// Minimum content length
  static const int minContentLength = 25;

  /// Maximum content length
  static const int maxContentLength = 611;

  /// Maximum number of attachments
  static const int maxAttachments = 5;

  /// Maximum number of tags
  static const int maxTags = 10;

  /// Maximum tag length
  static const int maxTagLength = 50;

  /// Minimum word count for content
  static const int minContentWordCount = 7;

  /// Maximum word count for content
  static const int maxContentWordCount = 1000;
}
