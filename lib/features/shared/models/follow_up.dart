import 'package:cloud_firestore/cloud_firestore.dart';

/// A model class that represents a follow-up entry in Firestore.
class FollowUpModel {
  final String id;
  final FollowUpType type;
  final DateTime time;
  final List<String> triggers; // NEW: List of trigger IDs

  const FollowUpModel({
    required this.id,
    required this.type,
    required this.time,
    this.triggers = const [], // Default to empty list
  });

  /// Create a FollowUpModel from a Firestore document snapshot.
  factory FollowUpModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return FollowUpModel(
      id: doc.id,
      type: _fromStringToEnum(data['type'] as String? ?? 'relapse'),
      time: (data['time'] as Timestamp?)?.toDate() ?? DateTime.now(),
      triggers: List<String>.from(
          data['triggers'] as List? ?? []), // Handle triggers field
    );
  }

  /// Convert FollowUpModel to a Map for Firestore.
  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'time': Timestamp.fromDate(time),
      'triggers': triggers, // Include triggers in the map
    };
  }

  FollowUpModel copyWith({
    String? id,
    FollowUpType? type,
    DateTime? time,
    List<String>? triggers,
  }) {
    return FollowUpModel(
      id: id ?? this.id,
      type: type ?? this.type,
      time: time ?? this.time,
      triggers: triggers ?? this.triggers,
    );
  }

  /// Helper function to convert string to enum.
  static FollowUpType _fromStringToEnum(String typeStr) {
    return FollowUpType.values.firstWhere(
      (e) => e.name == typeStr,
      orElse: () => FollowUpType.relapse,
    );
  }

  List<Object?> get props => [id, type, time, triggers];
}

enum FollowUpType {
  relapse,
  pornOnly,
  mastOnly,
  slipUp,
  none,
}

class FollowUpModelDataModel {
  final FollowUpType type;
  final DateTime time;

  const FollowUpModelDataModel({
    required this.type,
    required this.time,
  });
}
