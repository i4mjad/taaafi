/// Statistics for a community profile
///
/// Contains aggregated data about user's activity in the community
class ProfileStatistics {
  /// Total number of posts created by this profile
  final int postCount;

  /// Total number of comments created by this profile
  final int commentCount;

  /// Total number of interactions (likes/dislikes) given by this profile
  final int interactionCount;

  /// Total number of interactions (likes/dislikes) received on profile's content
  final int receivedInteractionCount;

  /// Date when the profile was deleted (null if not deleted)
  final DateTime? deletedAt;

  /// Number of days the profile was active
  final int activeDays;

  const ProfileStatistics({
    required this.postCount,
    required this.commentCount,
    required this.interactionCount,
    required this.receivedInteractionCount,
    this.deletedAt,
    required this.activeDays,
  });

  /// Creates a ProfileStatistics from JSON data
  factory ProfileStatistics.fromJson(Map<String, dynamic> json) {
    return ProfileStatistics(
      postCount: json['postCount'] as int? ?? 0,
      commentCount: json['commentCount'] as int? ?? 0,
      interactionCount: json['interactionCount'] as int? ?? 0,
      receivedInteractionCount: json['receivedInteractionCount'] as int? ?? 0,
      deletedAt: json['deletedAt'] != null
          ? DateTime.parse(json['deletedAt'] as String)
          : null,
      activeDays: json['activeDays'] as int? ?? 0,
    );
  }

  /// Converts to JSON
  Map<String, dynamic> toJson() {
    return {
      'postCount': postCount,
      'commentCount': commentCount,
      'interactionCount': interactionCount,
      'receivedInteractionCount': receivedInteractionCount,
      'deletedAt': deletedAt?.toIso8601String(),
      'activeDays': activeDays,
    };
  }

  /// Gets total activity count (posts + comments)
  int get totalActivityCount => postCount + commentCount;

  /// Checks if profile has any activity
  bool get hasActivity => totalActivityCount > 0;
}
