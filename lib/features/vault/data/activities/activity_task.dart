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

  factory ActivityTask.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ActivityTask(
      id: doc.id,
      name: data['taskName'] as String,
      description: data['taskDescription'] as String,
      frequency: _frequencyFromString(data['taskFrequency'] as String),
    );
  }

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
