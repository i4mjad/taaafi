import 'package:cloud_firestore/cloud_firestore.dart';

/// A model class that represents a follow-up entry in Firestore.
class FollowUpModel {
  final String id;
  final FollowUpType type;
  final DateTime time;

  const FollowUpModel({
    required this.id,
    required this.type,
    required this.time,
  });

  /// Create a FollowUpModel from a Firestore document snapshot.
  factory FollowUpModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return FollowUpModel(
      id: doc.id,
      type: _fromStringToEnum(data['type'] as String? ?? 'relapse'),
      time: (data['time'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert FollowUpModel to a Map for Firestore.
  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'time': Timestamp.fromDate(time),
    };
  }

  FollowUpModel copyWith({
    String? id,
    FollowUpType? type,
    DateTime? time,
  }) {
    return FollowUpModel(
      id: id ?? this.id,
      type: type ?? this.type,
      time: time ?? this.time,
    );
  }

  /// Helper function to convert string to enum.
  static FollowUpType _fromStringToEnum(String typeStr) {
    return FollowUpType.values.firstWhere(
      (e) => e.name == typeStr,
      orElse: () => FollowUpType.relapse,
    );
  }

  List<Object?> get props => [id, type, time];
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
