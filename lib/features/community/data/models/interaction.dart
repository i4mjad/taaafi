import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a user interaction with a post or comment
///
/// This model stores likes and dislikes in a separate collection for better
/// scalability and performance. The document ID follows the pattern:
/// {userCPId}_{targetType}_{targetId} to prevent duplicate interactions
class Interaction {
  final String id;
  final String targetType; // 'post' or 'comment'
  final String targetId; // postId or commentId
  final String userCPId; // The user who made the interaction
  final String type; // 'like' (extensible for future types)
  final int value; // 1 for like, -1 for dislike, 0 for neutral
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Interaction({
    required this.id,
    required this.targetType,
    required this.targetId,
    required this.userCPId,
    required this.type,
    required this.value,
    required this.createdAt,
    this.updatedAt,
  });

  factory Interaction.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Interaction(
      id: doc.id,
      targetType: data['targetType'] as String,
      targetId: data['targetId'] as String,
      userCPId: data['userCPId'] as String,
      type: data['type'] as String,
      value: data['value'] as int,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'targetType': targetType,
        'targetId': targetId,
        'userCPId': userCPId,
        'type': type,
        'value': value,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };

  /// Converts Interaction to Firestore document data
  /// Excludes the id field as it's stored as the document ID
  Map<String, dynamic> toFirestore() => {
        'targetType': targetType,
        'targetId': targetId,
        'userCPId': userCPId,
        'type': type,
        'value': value,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      };

  /// Generates a document ID for this interaction
  /// Format: {userCPId}_{targetType}_{targetId}
  static String generateDocumentId({
    required String userCPId,
    required String targetType,
    required String targetId,
  }) {
    return '${userCPId}_${targetType}_$targetId';
  }

  /// Creates a new interaction instance
  factory Interaction.create({
    required String targetType,
    required String targetId,
    required String userCPId,
    required String type,
    required int value,
  }) {
    final id = generateDocumentId(
      userCPId: userCPId,
      targetType: targetType,
      targetId: targetId,
    );

    return Interaction(
      id: id,
      targetType: targetType,
      targetId: targetId,
      userCPId: userCPId,
      type: type,
      value: value,
      createdAt: DateTime.now(),
    );
  }

  /// Creates a copy of this interaction with updated values
  Interaction copyWith({
    String? id,
    String? targetType,
    String? targetId,
    String? userCPId,
    String? type,
    int? value,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Interaction(
      id: id ?? this.id,
      targetType: targetType ?? this.targetType,
      targetId: targetId ?? this.targetId,
      userCPId: userCPId ?? this.userCPId,
      type: type ?? this.type,
      value: value ?? this.value,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Updates this interaction with a new value and timestamp
  Interaction updateValue(int newValue) {
    return copyWith(
      value: newValue,
      updatedAt: DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Interaction &&
        other.id == id &&
        other.targetType == targetType &&
        other.targetId == targetId &&
        other.userCPId == userCPId &&
        other.type == type &&
        other.value == value &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      targetType,
      targetId,
      userCPId,
      type,
      value,
      createdAt,
      updatedAt,
    );
  }

  @override
  String toString() {
    return 'Interaction(id: $id, targetType: $targetType, targetId: $targetId, userCPId: $userCPId, type: $type, value: $value, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}
