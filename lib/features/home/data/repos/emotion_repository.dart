import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:reboot_app_3/features/home/data/models/emotion_model.dart';

/// Responsible for all Firestore interactions related to emotions.
class EmotionRepository {
  final FirebaseFirestore _firestore;

  EmotionRepository(this._firestore);

  String? _getUserId() {
    return FirebaseAuth.instance.currentUser?.uid;
  }

  /// Create a new emotion document under `users/{uid}/emotions`.
  Future<void> createEmotion({
    required EmotionModel emotion,
  }) async {
    final uid = _getUserId();
    if (uid == null) throw Exception('User not logged in');
    final docRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('emotions')
        .doc(); // Generate ID by Firestore
    await docRef.set(emotion.copyWith(id: docRef.id).toMap());
  }

  /// Create multiple emotion documents under `users/{uid}/emotions`.
  Future<void> createMultipleEmotions({
    required List<EmotionModel> emotions,
  }) async {
    final uid = _getUserId();
    if (uid == null) throw Exception('User not logged in');
    final batch = _firestore.batch();
    for (var emotion in emotions) {
      final docRef = _firestore
          .collection('users')
          .doc(uid)
          .collection('emotions')
          .doc(); // Generate ID by Firestore
      batch.set(docRef, emotion.copyWith(id: docRef.id).toMap());
    }
    await batch.commit();
  }

  /// Read a single emotion by its ID.
  Future<EmotionModel?> readEmotion({
    required String emotionId,
  }) async {
    final uid = _getUserId();
    if (uid == null) throw Exception('User not logged in');
    final docRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('emotions')
        .doc(emotionId);
    final doc = await docRef.get();
    if (doc.exists) {
      return EmotionModel.fromDoc(doc);
    }
    return null;
  }

  /// Read all emotions for the user on a specific date.
  Future<List<EmotionModel>> readEmotionsByDate(DateTime date) async {
    final uid = _getUserId();
    if (uid == null) throw Exception('User not logged in');
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
    final querySnapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('emotions')
        .where('date', isGreaterThanOrEqualTo: startOfDay)
        .where('date', isLessThanOrEqualTo: endOfDay)
        .get();
    return querySnapshot.docs.map((doc) => EmotionModel.fromDoc(doc)).toList();
  }

  /// Update an existing emotion.
  Future<void> updateEmotion({
    required EmotionModel emotion,
  }) async {
    final uid = _getUserId();
    if (uid == null) throw Exception('User not logged in');
    final docRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('emotions')
        .doc(emotion.id);
    await docRef.update(emotion.toMap());
  }

  /// Delete a single emotion by its ID.
  Future<void> deleteEmotion({
    required String emotionId,
  }) async {
    final uid = _getUserId();
    if (uid == null) throw Exception('User not logged in');
    final docRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('emotions')
        .doc(emotionId);
    await docRef.delete();
  }

  /// Delete the entire `emotions` sub-collection for the user.
  Future<void> deleteAllEmotions() async {
    final uid = _getUserId();
    if (uid == null) throw Exception('User not logged in');
    final collectionRef =
        _firestore.collection('users').doc(uid).collection('emotions');
    final querySnapshot = await collectionRef.get();
    for (var doc in querySnapshot.docs) {
      await doc.reference.delete();
    }
  }
}
