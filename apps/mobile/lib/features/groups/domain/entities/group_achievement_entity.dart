import 'package:cloud_firestore/cloud_firestore.dart';

/// Domain entity for group achievements
///
/// Represents an achievement earned by a member in a group
/// Sprint 4 - Feature 4.1: Enhanced Member Profiles
class GroupAchievementEntity {
  final String id;
  final String groupId;
  final String cpId;
  final String achievementType;
  final String title;
  final String description;
  final String? iconUrl;
  final DateTime earnedAt;

  const GroupAchievementEntity({
    required this.id,
    required this.groupId,
    required this.cpId,
    required this.achievementType,
    required this.title,
    required this.description,
    this.iconUrl,
    required this.earnedAt,
  });

  /// Helper method to convert timestamp fields from Firestore or JSON
  static DateTime _parseTimestamp(dynamic value) {
    if (value == null) {
      throw ArgumentError('Timestamp cannot be null');
    }

    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is String) {
      return DateTime.parse(value);
    }

    if (value is DateTime) {
      return value;
    }

    throw ArgumentError('Invalid timestamp type: ${value.runtimeType}');
  }

  /// Creates a GroupAchievementEntity from JSON data
  factory GroupAchievementEntity.fromJson(Map<String, dynamic> json) {
    return GroupAchievementEntity(
      id: json['id'] as String,
      groupId: json['groupId'] as String,
      cpId: json['cpId'] as String,
      achievementType: json['achievementType'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      iconUrl: json['iconUrl'] as String?,
      earnedAt: _parseTimestamp(json['earnedAt']),
    );
  }

  /// Converts the entity to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'groupId': groupId,
      'cpId': cpId,
      'achievementType': achievementType,
      'title': title,
      'description': description,
      'iconUrl': iconUrl,
      'earnedAt': earnedAt.toIso8601String(),
    };
  }

  /// Creates a copy of this entity with updated fields
  GroupAchievementEntity copyWith({
    String? id,
    String? groupId,
    String? cpId,
    String? achievementType,
    String? title,
    String? description,
    String? iconUrl,
    DateTime? earnedAt,
  }) {
    return GroupAchievementEntity(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      cpId: cpId ?? this.cpId,
      achievementType: achievementType ?? this.achievementType,
      title: title ?? this.title,
      description: description ?? this.description,
      iconUrl: iconUrl ?? this.iconUrl,
      earnedAt: earnedAt ?? this.earnedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GroupAchievementEntity &&
        other.id == id &&
        other.groupId == groupId &&
        other.cpId == cpId &&
        other.achievementType == achievementType &&
        other.title == title &&
        other.description == description &&
        other.iconUrl == iconUrl &&
        other.earnedAt == earnedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        groupId.hashCode ^
        cpId.hashCode ^
        achievementType.hashCode ^
        title.hashCode ^
        description.hashCode ^
        iconUrl.hashCode ^
        earnedAt.hashCode;
  }

  @override
  String toString() {
    return 'GroupAchievementEntity(id: $id, groupId: $groupId, cpId: $cpId, achievementType: $achievementType, title: $title, description: $description, iconUrl: $iconUrl, earnedAt: $earnedAt)';
  }
}

/// Achievement type constants
class AchievementType {
  static const String firstMessage = 'first_message';
  static const String welcome = 'welcome';
  static const String weekWarrior = 'week_warrior';
  static const String monthMaster = 'month_master';
  static const String helpful = 'helpful';
  static const String topContributor = 'top_contributor';

  /// Get all achievement types
  static List<String> get all => [
        firstMessage,
        welcome,
        weekWarrior,
        monthMaster,
        helpful,
        topContributor,
      ];

  /// Check if an achievement type is valid
  static bool isValid(String type) {
    return all.contains(type);
  }
}

