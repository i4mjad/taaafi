import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:reboot_app_3/features/community/domain/entities/community_profile_entity.dart';
import 'package:reboot_app_3/features/community/data/models/notification_preferences.dart';

/// Data model for community profiles
///
/// This model handles the data layer concerns including serialization,
/// deserialization, and mapping to/from the domain entity.
class CommunityProfileModel {
  /// Unique identifier for the community profile (generated ID)
  final String id;

  /// Firebase Auth User UID for reference (not used for lookups)
  /// This enables future features like multiple community profiles per user
  final String userUID;

  /// Display name shown to other community members
  final String displayName;

  /// User's gender (male/female/other)
  final String gender;

  /// URL to the user's avatar image
  final String? avatarUrl;

  /// Whether the user posts anonymously by default
  final bool isAnonymous;

  /// Whether the profile has been soft deleted
  final bool isDeleted;

  /// Whether the user has an active Plus subscription
  final bool? isPlusUser;

  /// Whether the user allows sharing their relapse streak information (Plus feature)
  final bool shareRelapseStreaks;

  /// Current streak in days (only stored if user shares streaks)
  final int? currentStreakDays;

  /// Last time streak data was updated
  final DateTime? streakLastUpdated;

  /// User's role in the community (member, admin, moderator)
  final String role;

  /// When the profile was created
  final DateTime createdAt;

  /// When the profile was last updated
  final DateTime? updatedAt;

  /// User's notification preferences for community features
  final NotificationPreferences? notificationPreferences;

  const CommunityProfileModel({
    required this.id,
    required this.userUID,
    required this.displayName,
    required this.gender,
    this.avatarUrl,
    required this.isAnonymous,
    this.isDeleted = false,
    this.isPlusUser,
    this.shareRelapseStreaks = false,
    this.currentStreakDays,
    this.streakLastUpdated,
    required this.role,
    required this.createdAt,
    this.updatedAt,
    this.notificationPreferences,
  });

  /// Helper method to convert timestamp fields from Firestore or JSON
  static DateTime? _parseTimestamp(dynamic value) {
    if (value == null) return null;

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

  /// Creates a CommunityProfileModel from JSON data
  factory CommunityProfileModel.fromJson(Map<String, dynamic> json) {
    return CommunityProfileModel(
      id: json['id'] as String,
      userUID: json['userUID'] as String,
      displayName: json['displayName'] as String,
      gender: json['gender'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      isAnonymous: json['isAnonymous'] as bool,
      isDeleted: json['isDeleted'] ?? false,
      isPlusUser: json['isPlusUser'] as bool?,
      shareRelapseStreaks: json['shareRelapseStreaks'] as bool? ?? false,
      currentStreakDays: json['currentStreakDays'] as int?,
      streakLastUpdated: _parseTimestamp(json['streakLastUpdated']),
      role: json['role'] as String,
      createdAt: _parseTimestamp(json['createdAt'])!,
      updatedAt: _parseTimestamp(json['updatedAt']),
      notificationPreferences: json['notificationPreferences'] != null
          ? NotificationPreferences.fromJson(
              json['notificationPreferences'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Creates a CommunityProfileModel from Firestore document
  factory CommunityProfileModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return CommunityProfileModel(
      id: doc.id,
      userUID: data['userUID'] as String,
      displayName: data['displayName'] as String,
      gender: data['gender'] as String,
      avatarUrl: data['avatarUrl'] as String?,
      isAnonymous: data['isAnonymous'] as bool,
      isDeleted: data['isDeleted'] ?? false,
      isPlusUser: data['isPlusUser'] as bool?,
      shareRelapseStreaks: data['shareRelapseStreaks'] as bool? ?? false,
      currentStreakDays: data['currentStreakDays'] as int?,
      streakLastUpdated: data['streakLastUpdated'] != null
          ? (data['streakLastUpdated'] as Timestamp).toDate()
          : null,
      role: data['role'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      notificationPreferences: data['notificationPreferences'] != null
          ? NotificationPreferences.fromJson(
              data['notificationPreferences'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Creates a CommunityProfileModel from domain entity
  factory CommunityProfileModel.fromEntity(CommunityProfileEntity entity) {
    return CommunityProfileModel(
      id: entity.id,
      userUID: entity.userUID,
      displayName: entity.displayName,
      gender: entity.gender,
      avatarUrl: entity.avatarUrl,
      isAnonymous: entity.isAnonymous,
      isDeleted: entity.isDeleted,
      isPlusUser: entity.isPlusUser,
      shareRelapseStreaks: entity.shareRelapseStreaks,
      currentStreakDays: entity.currentStreakDays,
      streakLastUpdated: entity.streakLastUpdated,
      role: entity.role,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      notificationPreferences: entity.notificationPreferences,
    );
  }

  /// Converts to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userUID': userUID,
      'displayName': displayName,
      'gender': gender,
      'avatarUrl': avatarUrl,
      'isAnonymous': isAnonymous,
      'isDeleted': isDeleted,
      'isPlusUser': isPlusUser,
      'shareRelapseStreaks': shareRelapseStreaks,
      'role': role,
      // Streak data is read directly from user documents, not stored in community profiles
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'notificationPreferences': notificationPreferences?.toJson(),
    };
  }

  /// Converts to Firestore document data
  Map<String, dynamic> toFirestore() {
    return {
      'userUID': userUID,
      'displayName': displayName,
      'gender': gender,
      'avatarUrl': avatarUrl,
      'isAnonymous': isAnonymous,
      'isDeleted': isDeleted,
      'isPlusUser': isPlusUser,
      'shareRelapseStreaks': shareRelapseStreaks,
      'role': role,
      // Streak data is read directly from user documents, not stored in community profiles
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'notificationPreferences': notificationPreferences?.toJson(),
    };
  }

  /// Converts to domain entity
  CommunityProfileEntity toEntity() {
    return CommunityProfileEntity(
      id: id,
      userUID: userUID,
      displayName: displayName,
      gender: gender,
      avatarUrl: avatarUrl,
      isAnonymous: isAnonymous,
      isDeleted: isDeleted,
      isPlusUser: isPlusUser,
      shareRelapseStreaks: shareRelapseStreaks,
      currentStreakDays: currentStreakDays,
      streakLastUpdated: streakLastUpdated,
      role: role,
      createdAt: createdAt,
      updatedAt: updatedAt,
      notificationPreferences: notificationPreferences,
    );
  }

  /// Creates a copy with updated fields
  CommunityProfileModel copyWith({
    String? id,
    String? userUID,
    String? displayName,
    String? gender,
    String? avatarUrl,
    bool? isAnonymous,
    bool? isDeleted,
    bool? isPlusUser,
    bool? shareRelapseStreaks,
    int? currentStreakDays,
    DateTime? streakLastUpdated,
    String? role,
    DateTime? createdAt,
    DateTime? updatedAt,
    NotificationPreferences? notificationPreferences,
  }) {
    return CommunityProfileModel(
      id: id ?? this.id,
      userUID: userUID ?? this.userUID,
      displayName: displayName ?? this.displayName,
      gender: gender ?? this.gender,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      isDeleted: isDeleted ?? this.isDeleted,
      isPlusUser: isPlusUser ?? this.isPlusUser,
      shareRelapseStreaks: shareRelapseStreaks ?? this.shareRelapseStreaks,
      currentStreakDays: currentStreakDays ?? this.currentStreakDays,
      streakLastUpdated: streakLastUpdated ?? this.streakLastUpdated,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      notificationPreferences:
          notificationPreferences ?? this.notificationPreferences,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CommunityProfileModel &&
        other.id == id &&
        other.userUID == userUID &&
        other.displayName == displayName &&
        other.gender == gender &&
        other.avatarUrl == avatarUrl &&
        other.isAnonymous == isAnonymous &&
        other.isDeleted == isDeleted &&
        other.isPlusUser == isPlusUser &&
        other.shareRelapseStreaks == shareRelapseStreaks &&
        other.currentStreakDays == currentStreakDays &&
        other.streakLastUpdated == streakLastUpdated &&
        other.role == role &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.notificationPreferences == notificationPreferences;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        userUID.hashCode ^
        displayName.hashCode ^
        gender.hashCode ^
        avatarUrl.hashCode ^
        isAnonymous.hashCode ^
        isDeleted.hashCode ^
        isPlusUser.hashCode ^
        shareRelapseStreaks.hashCode ^
        currentStreakDays.hashCode ^
        streakLastUpdated.hashCode ^
        role.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode ^
        notificationPreferences.hashCode;
  }

  /// Business logic: Get display name following the pipeline: deleted → anonymous → actual name
  String getDisplayNameWithPipeline() {
    // 1. First check if user is deleted - if yes, display "deleted" text
    if (isDeleted) {
      return 'DELETED_USER'; // This will be localized in the UI
    }

    // 2. Then check if they are anonymous - if yes, don't show their name
    if (isAnonymous) {
      return 'ANONYMOUS_USER'; // This will be localized in the UI
    }

    // 3. If neither deleted nor anonymous, display their actual name
    return displayName.isNotEmpty ? displayName : 'Community Member';
  }

  @override
  String toString() {
    return 'CommunityProfileModel(id: $id, userUID: $userUID, displayName: $displayName, gender: $gender, avatarUrl: $avatarUrl, isAnonymous: $isAnonymous, isDeleted: $isDeleted, isPlusUser: $isPlusUser, shareRelapseStreaks: $shareRelapseStreaks, currentStreakDays: $currentStreakDays, streakLastUpdated: $streakLastUpdated, role: $role, createdAt: $createdAt, updatedAt: $updatedAt, notificationPreferences: $notificationPreferences)';
  }
}
