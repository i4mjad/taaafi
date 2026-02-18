import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

/// Script to remove all one-time tasks from group challenges in Firestore
/// Run this once to clean up the database after removing one-time task support
void main() async {
  print('🧹 Starting cleanup: Removing one-time tasks from Firestore...\n');

  try {
    // Initialize Firebase (you may need to configure this based on your setup)
    await Firebase.initializeApp();
    
    final firestore = FirebaseFirestore.instance;
    final challengesCollection = firestore.collection('group_challenges');
    
    // Get all challenges
    final snapshot = await challengesCollection.get();
    print('📊 Found ${snapshot.docs.length} challenges to check\n');
    
    int challengesUpdated = 0;
    int tasksRemoved = 0;
    
    // Process each challenge
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final challengeName = data['name'] ?? 'Unknown';
      final tasks = data['tasks'] as List<dynamic>? ?? [];
      
      if (tasks.isEmpty) continue;
      
      // Filter out one-time tasks
      final filteredTasks = tasks.where((task) {
        final frequency = task['frequency'] as String?;
        return frequency != 'one_time';
      }).toList();
      
      final removedCount = tasks.length - filteredTasks.length;
      
      if (removedCount > 0) {
        // Update the challenge with filtered tasks
        await doc.reference.update({'tasks': filteredTasks});
        
        challengesUpdated++;
        tasksRemoved += removedCount;
        
        print('✅ Challenge: "$challengeName"');
        print('   Removed $removedCount one-time task(s)');
        print('   Remaining tasks: ${filteredTasks.length}\n');
      }
    }
    
    print('\n🎉 Cleanup complete!');
    print('   Challenges updated: $challengesUpdated');
    print('   One-time tasks removed: $tasksRemoved');
    
  } catch (e, stackTrace) {
    print('❌ Error during cleanup: $e');
    print('Stack trace: $stackTrace');
    exit(1);
  }
  
  exit(0);
}

