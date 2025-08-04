import 'package:cloud_firestore/cloud_firestore.dart';

/// Community Profile Entity
///
/// Represents a user's community profile with all necessary information
/// for participating in the community forums and interactions.
class CommunityProfileEntity {
  final String id;
  final String userUID;
  final String displayName;
  final String gender;
  final String? avatarUrl;
  final bool isAnonymous;
  final bool isDeleted;
  final bool? isPlusUser;
  final bool shareRelapseStreaks;
  final int? currentStreakDays;
  final DateTime? streakLastUpdated;
  final String role; // 'member', 'admin', 'moderator'
  final DateTime createdAt;
  final DateTime? updatedAt;

  const CommunityProfileEntity({
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

  /// Creates a CommunityProfileEntity from JSON data
  factory CommunityProfileEntity.fromJson(Map<String, dynamic> json) {
    return CommunityProfileEntity(
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
    );
  }

  /// Converts the entity to JSON
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

  /// Business logic: Check if user has Plus subscription
  bool hasPlusSubscription() {
    return isPlusUser ?? false;
  }

  /// Business logic: Check if user can share relapse streaks (Plus users only)
  bool canShareRelapseStreaks() {
    final hasPlus = hasPlusSubscription();
    final allowsSharing = shareRelapseStreaks;
    return hasPlus && allowsSharing;
  }

  /// Business logic: Check if streak data is available and up to date
  bool hasValidStreakData() {
    if (!canShareRelapseStreaks() || currentStreakDays == null) {
      return false;
    }

    if (streakLastUpdated == null) {
      return false;
    }

    final now = DateTime.now();
    final difference = now.difference(streakLastUpdated!);
    final isRecent = difference.inHours < 24;

    return isRecent;
  }

  /// Business logic: Check if user is an admin
  bool isAdmin() {
    return role.toLowerCase() == 'admin';
  }

  /// Business logic: Check if user is a moderator
  bool isModerator() {
    return role.toLowerCase() == 'moderator';
  }

  /// Business logic: Check if user has elevated privileges (admin or moderator)
  bool hasElevatedPrivileges() {
    return isAdmin() || isModerator();
  }

  /// Business logic: Get localized role display name
  String getRoleDisplayName() {
    switch (role.toLowerCase()) {
      case 'admin':
        return 'Admin';
      case 'moderator':
        return 'Moderator';
      case 'member':
      default:
        return 'Member';
    }
  }

  /// Business logic: Get display name with fallback
  String getDisplayName() {
    return displayName.isNotEmpty ? displayName : 'Community Member';
  }

  /// Business logic: Get display name following the pipeline: deleted → anonymous → actual name
  String getDisplayNameWithPipeline() {
    // 1. First check if user is deleted - if yes, display "deleted" text
    if (isDeleted) {
      print('🔍 [CommunityProfileEntity] -> Returning DELETED_USER');
      return 'DELETED_USER'; // This will be localized in the UI
    }

    // 2. Then check if they are anonymous - if yes, don't show their name
    if (isAnonymous) {
      print('🔍 [CommunityProfileEntity] -> Returning ANONYMOUS_USER');
      return 'ANONYMOUS_USER'; // This will be localized in the UI
    }

    // 3. If neither deleted nor anonymous, display their actual name
    final result = displayName.isNotEmpty ? displayName : 'Community Member';
    print('🔍 [CommunityProfileEntity] -> Returning actual name: "$result"');
    return result;
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
  }) {
    return CommunityProfileEntity(
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
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CommunityProfileEntity &&
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
        other.updatedAt == updatedAt;
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
        updatedAt.hashCode;
  }

  @override
  String toString() {
    return 'CommunityProfileEntity(id: $id, userUID: $userUID, displayName: $displayName, gender: $gender, avatarUrl: $avatarUrl, isAnonymous: $isAnonymous, isDeleted: $isDeleted, isPlusUser: $isPlusUser, shareRelapseStreaks: $shareRelapseStreaks, currentStreakDays: $currentStreakDays, streakLastUpdated: $streakLastUpdated, role: $role, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}
