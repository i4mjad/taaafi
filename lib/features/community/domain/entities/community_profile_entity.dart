/// Domain entity representing a community profile
///
/// This is the core business object that encapsulates all the business logic
/// and rules for community profiles. It's independent of external frameworks
/// and can be used across different layers of the application.
class CommunityProfileEntity {
  /// Unique identifier for the community profile
  final String id;

  /// Display name shown to other community members
  final String displayName;

  /// User's gender (male/female/other)
  final String gender;

  /// URL to the user's avatar image
  final String? avatarUrl;

  /// Whether the user posts anonymously by default
  final bool postAnonymouslyByDefault;

  /// When the profile was created
  final DateTime createdAt;

  /// When the profile was last updated
  final DateTime? updatedAt;

  const CommunityProfileEntity({
    required this.id,
    required this.displayName,
    required this.gender,
    this.avatarUrl,
    required this.postAnonymouslyByDefault,
    required this.createdAt,
    this.updatedAt,
  });

  /// Creates a CommunityProfileEntity from JSON data
  factory CommunityProfileEntity.fromJson(Map<String, dynamic> json) {
    return CommunityProfileEntity(
      id: json['id'] as String,
      displayName: json['displayName'] as String,
      gender: json['gender'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      postAnonymouslyByDefault: json['postAnonymouslyByDefault'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  /// Converts the entity to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'displayName': displayName,
      'gender': gender,
      'avatarUrl': avatarUrl,
      'postAnonymouslyByDefault': postAnonymouslyByDefault,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  /// Business logic: Check if user has a custom avatar
  bool hasCustomAvatar() {
    return avatarUrl != null && avatarUrl!.isNotEmpty;
  }

  /// Business logic: Check if this is a new profile (created recently)
  bool isNewProfile() {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    return difference.inDays < 7; // Consider new if created within 7 days
  }

  /// Business logic: Get display name with fallback
  String getDisplayName() {
    return displayName.isNotEmpty ? displayName : 'Community Member';
  }

  /// Business logic: Validate profile data
  bool isValid() {
    return displayName.isNotEmpty &&
        displayName.length >= 2 &&
        displayName.length <= 50 &&
        ['male', 'female', 'other'].contains(gender.toLowerCase());
  }

  /// Creates a copy of this entity with updated fields
  CommunityProfileEntity copyWith({
    String? id,
    String? displayName,
    String? gender,
    String? avatarUrl,
    bool? postAnonymouslyByDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CommunityProfileEntity(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      gender: gender ?? this.gender,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      postAnonymouslyByDefault:
          postAnonymouslyByDefault ?? this.postAnonymouslyByDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CommunityProfileEntity &&
        other.id == id &&
        other.displayName == displayName &&
        other.gender == gender &&
        other.avatarUrl == avatarUrl &&
        other.postAnonymouslyByDefault == postAnonymouslyByDefault &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        displayName.hashCode ^
        gender.hashCode ^
        avatarUrl.hashCode ^
        postAnonymouslyByDefault.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode;
  }

  @override
  String toString() {
    return 'CommunityProfileEntity(id: $id, displayName: $displayName, gender: $gender, avatarUrl: $avatarUrl, postAnonymouslyByDefault: $postAnonymouslyByDefault, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}
