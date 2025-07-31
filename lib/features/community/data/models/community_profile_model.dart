import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/community_profile_entity.dart';

/// Data model for community profile
///
/// This model handles the serialization/deserialization of community profile data
/// to/from external data sources like Firestore. It acts as a bridge between
/// the domain layer and the data persistence layer.
class CommunityProfileModel {
  /// Unique identifier for the community profile
  final String id;

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

  /// When the profile was created
  final DateTime createdAt;

  /// When the profile was last updated
  final DateTime? updatedAt;

  const CommunityProfileModel({
    required this.id,
    required this.displayName,
    required this.gender,
    this.avatarUrl,
    required this.isAnonymous,
    this.isDeleted = false,
    this.isPlusUser,
    required this.createdAt,
    this.updatedAt,
  });

  /// Creates a CommunityProfileModel from JSON data
  factory CommunityProfileModel.fromJson(Map<String, dynamic> json) {
    return CommunityProfileModel(
      id: json['id'] as String,
      displayName: json['displayName'] as String,
      gender: json['gender'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      isAnonymous: json['isAnonymous'] as bool,
      isDeleted: json['isDeleted'] ?? false,
      isPlusUser: json['isPlusUser'] as bool?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  /// Converts the model to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'displayName': displayName,
      'gender': gender,
      'avatarUrl': avatarUrl,
      'isAnonymous': isAnonymous,
      'isDeleted': isDeleted,
      'isPlusUser': isPlusUser,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  /// Creates a CommunityProfileModel from Firestore document
  factory CommunityProfileModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return CommunityProfileModel(
      id: doc.id,
      displayName: data['displayName'] as String,
      gender: data['gender'] as String,
      avatarUrl: data['avatarUrl'] as String?,
      isAnonymous: data['isAnonymous'] as bool,
      isDeleted: data['isDeleted'] ?? false,
      isPlusUser: data['isPlusUser'] as bool?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  /// Converts the model to Firestore document data
  Map<String, dynamic> toFirestore() {
    return {
      'displayName': displayName,
      'gender': gender,
      'avatarUrl': avatarUrl,
      'isAnonymous': isAnonymous,
      'isDeleted': isDeleted,
      'isPlusUser': isPlusUser,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  /// Converts the model to domain entity
  CommunityProfileEntity toEntity() {
    return CommunityProfileEntity(
      id: id,
      displayName: displayName,
      gender: gender,
      avatarUrl: avatarUrl,
      isAnonymous: isAnonymous,
      isDeleted: isDeleted,
      isPlusUser: isPlusUser,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Creates a model from domain entity
  factory CommunityProfileModel.fromEntity(CommunityProfileEntity entity) {
    return CommunityProfileModel(
      id: entity.id,
      displayName: entity.displayName,
      gender: entity.gender,
      avatarUrl: entity.avatarUrl,
      isAnonymous: entity.isAnonymous,
      isDeleted: entity.isDeleted,
      isPlusUser: entity.isPlusUser,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  /// Creates a copy of this model with updated fields
  CommunityProfileModel copyWith({
    String? id,
    String? displayName,
    String? gender,
    String? avatarUrl,
    bool? isAnonymous,
    bool? isDeleted,
    bool? isPlusUser,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CommunityProfileModel(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      gender: gender ?? this.gender,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      isDeleted: isDeleted ?? this.isDeleted,
      isPlusUser: isPlusUser ?? this.isPlusUser,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CommunityProfileModel &&
        other.id == id &&
        other.displayName == displayName &&
        other.gender == gender &&
        other.avatarUrl == avatarUrl &&
        other.isAnonymous == isAnonymous &&
        other.isDeleted == isDeleted &&
        other.isPlusUser == isPlusUser &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        displayName.hashCode ^
        gender.hashCode ^
        avatarUrl.hashCode ^
        isAnonymous.hashCode ^
        isDeleted.hashCode ^
        isPlusUser.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode;
  }

  @override
  String toString() {
    return 'CommunityProfileModel(id: $id, displayName: $displayName, gender: $gender, avatarUrl: $avatarUrl, isAnonymous: $isAnonymous, isDeleted: $isDeleted, isPlusUser: $isPlusUser, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}
