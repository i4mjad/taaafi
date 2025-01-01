import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:reboot_app_3/features/vault/data/activities/activity_task.dart';
import 'package:reboot_app_3/features/vault/data/activities/ongoing_activity_task.dart';
import 'package:reboot_app_3/features/vault/data/diaries/diary.dart';

abstract class DiariesRepository {
  Future<List<Diary>> getDiaries();
  Future<void> addDiary(Diary diary);
  Future<void> updateDiary(String diaryId, Diary diary);
  Future<void> deleteDiary(String diaryId);
  Future<Diary?> getDiaryById(String diaryId);
}

class FirebaseDiariesRepository implements DiariesRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  FirebaseDiariesRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  String get _userId {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');
    return user.uid;
  }

  @override
  Future<List<Diary>> getDiaries() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('userNotes')
          .get();

      return snapshot.docs
          .map((doc) => Diary(
                doc.id,
                doc.data()['title'] as String,
                doc.data()['body'] as String, // Using body for plainText
                (doc.data()['timestamp'] as Timestamp).toDate(),
                formattedContent:
                    doc.data()['formattedContent'] as List<dynamic>?,
                updatedAt: doc.data()['updatedAt'] != null
                    ? (doc.data()['updatedAt'] as Timestamp).toDate()
                    : null,
              ))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch diaries: $e');
    }
  }

  @override
  Future<Diary?> getDiaryById(String diaryId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('userNotes')
          .doc(diaryId)
          .get();

      if (!doc.exists) return null;

      final data = doc.data()!;
      final linkedTaskIds = (data['linkedTaskIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [];

      // Fetch linked tasks if there are any
      final linkedTasks = linkedTaskIds.isNotEmpty
          ? await Future.wait(
              linkedTaskIds.map((taskId) => _getTaskDetails(taskId)))
          : <OngoingActivityTask>[];

      return Diary(
        doc.id,
        data['title'] as String,
        data['body'] as String,
        (data['timestamp'] as Timestamp).toDate(),
        formattedContent: data['formattedContent'] as List<dynamic>?,
        updatedAt: data['updatedAt'] != null
            ? (data['updatedAt'] as Timestamp).toDate()
            : null,
        linkedTaskIds: linkedTaskIds,
        linkedTasks: linkedTasks.whereType<OngoingActivityTask>().toList(),
      );
    } catch (e) {
      throw Exception('Failed to fetch diary: $e');
    }
  }

  Future<OngoingActivityTask?> _getTaskDetails(String taskId) async {
    try {
      // Query across all activities to find the task
      final taskQuery = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('ongoing_activities')
          .get();

      for (var activityDoc in taskQuery.docs) {
        final taskDoc = await activityDoc.reference
            .collection('scheduledTasks')
            .doc(taskId)
            .get();

        if (taskDoc.exists) {
          final baseTask = await _getBaseTask(
            activityDoc.id,
            taskDoc.data()!['taskId'] as String,
          );

          if (baseTask != null) {
            return OngoingActivityTask.fromFirestore(
                taskDoc, baseTask, taskDoc.id);
          }
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<ActivityTask?> _getBaseTask(String activityId, String taskId) async {
    try {
      final taskDoc = await _firestore
          .collection('activities')
          .doc(activityId)
          .collection('activityTasks')
          .doc(taskId)
          .get();

      if (!taskDoc.exists) return null;
      return ActivityTask.fromFirestore(taskDoc);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> updateDiary(String diaryId, Diary diary) async {
    try {
      print('Updating diary: ${diary.linkedTaskIds}');
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('userNotes')
          .doc(diaryId)
          .update({
        'title': diary.title,
        'body': diary.plainText,
        'formattedContent': diary.formattedContent,
        'timestamp': Timestamp.fromDate(diary.date),
        'updatedAt': FieldValue.serverTimestamp(),
        'linkedTaskIds': diary.linkedTaskIds,
      });
    } catch (e) {
      throw Exception('Failed to update diary: $e');
    }
  }

  @override
  Future<void> addDiary(Diary diary) async {
    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('userNotes')
          .add({
        'title': diary.title,
        'body': diary.plainText,
        'timestamp': Timestamp.fromDate(diary.date),
        'formattedContent': diary.formattedContent,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to add diary: $e');
    }
  }

  @override
  Future<void> deleteDiary(String diaryId) async {
    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('userNotes')
          .doc(diaryId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete diary: $e');
    }
  }
}
