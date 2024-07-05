import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

class FollowUp {
  String id;
  DateTime time;
  String type;
  FollowUp({
    required this.id,
    required this.time,
    required this.type,
  });

  FollowUp copyWith({
    String? id,
    DateTime? time,
    String? type,
  }) {
    return FollowUp(
      id: id ?? this.id,
      time: time ?? this.time,
      type: type ?? this.type,
    );
  }

  Map<String, dynamic> toMap() {
    final result = <String, dynamic>{};

    result.addAll({'id': id});
    result.addAll({'time': Timestamp.fromDate(time.toUtc())});
    result.addAll({'type': type});

    return result;
  }

  factory FollowUp.fromMap(Map<String, dynamic> map) {
    return FollowUp(
      id: map['id'] ?? '',
      time: DateTime.fromMillisecondsSinceEpoch(map['time']).toLocal(),
      type: map['type'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory FollowUp.fromJson(String source) =>
      FollowUp.fromMap(json.decode(source));

  @override
  String toString() => 'FollowUp(id: $id, time: $time, type: $type)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is FollowUp &&
        other.id == id &&
        other.time == time &&
        other.type == type;
  }

  @override
  int get hashCode => id.hashCode ^ time.hashCode ^ type.hashCode;
}

enum FollowUpTypes {
  relapse,
  pornOnly,
  mastOnly,
  slipUp,
}
