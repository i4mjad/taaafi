import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum FollowUpType {
  relapse,
  pornOnly,
  mastOnly,
  slipUp,
}

/// A model class that represents a follow-up entry in Firestore.
class FollowUpModel extends Equatable {
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

  /// Helper function to convert string to enum.
  static FollowUpType _fromStringToEnum(String typeStr) {
    return FollowUpType.values.firstWhere(
      (e) => e.name == typeStr,
      orElse: () => FollowUpType.relapse,
    );
  }

  @override
  List<Object?> get props => [id, type, time];
}
