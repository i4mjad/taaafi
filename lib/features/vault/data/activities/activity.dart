import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:reboot_app_3/features/vault/data/activities/activity_task.dart';

enum Difficulty {
  starter,
  intermediate,
  advanced,
}

class Activity {
  final String id;
  final String name;
  final String description;
  final Difficulty difficulty;
  final List<ActivityTask> tasks;
  final int subscriberCount;

  Activity({
    required this.id,
    required this.name,
    required this.description,
    required this.difficulty,
    required this.tasks,
    this.subscriberCount = 0,
  });

  /// Creates an Activity from a Firestore document
  factory Activity.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Activity(
      id: doc.id,
      name: data['activityName'] as String,
      description: data['activityDescription'] as String,
      difficulty: _difficultyFromString(data['activityDifficulty'] as String),
      tasks: [], // Tasks are loaded separately from subcollection
      subscriberCount: data['subscriberCount'] as int? ?? 0,
    );
  }

  static Difficulty _difficultyFromString(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'starter':
        return Difficulty.starter;
      case 'intermediate':
        return Difficulty.intermediate;
      case 'advanced':
        return Difficulty.advanced;
      default:
        throw ArgumentError('Invalid difficulty: $difficulty');
    }
  }
}
