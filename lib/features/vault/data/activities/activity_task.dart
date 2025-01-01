import 'package:cloud_firestore/cloud_firestore.dart';

class ActivityTask {
  final String id;
  final String name;
  final String description;
  final TaskFrequency frequency;

  ActivityTask({
    required this.id,
    required this.name,
    required this.description,
    required this.frequency,
  });

  ActivityTask copyWith({
    String? id,
    String? name,
    String? description,
    TaskFrequency? frequency,
  }) {
    return ActivityTask(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      frequency: frequency ?? this.frequency,
    );
  }

  factory ActivityTask.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ActivityTask(
      id: doc.id,
      name: data['taskName'] as String,
      description: data['taskDescription'] as String,
      frequency: _frequencyFromString(data['taskFrequency'] as String),
    );
  }

  factory ActivityTask.fromJson(Map<String, dynamic> json) {
    return ActivityTask(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      frequency: TaskFrequency.values.firstWhere(
        (f) => f.toString() == json['frequency'] as String,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'frequency': frequency.toString(),
      };

  static TaskFrequency _frequencyFromString(String frequency) {
    switch (frequency.toLowerCase()) {
      case 'daily':
        return TaskFrequency.daily;
      case 'weekly':
        return TaskFrequency.weekly;
      case 'monthly':
        return TaskFrequency.monthly;
      default:
        throw ArgumentError('Invalid frequency: $frequency');
    }
  }
}

enum TaskFrequency { daily, weekly, monthly }
