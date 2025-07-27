import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:reboot_app_3/features/vault/data/models/emotion_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EmotionRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  EmotionRepository(this._firestore, this._auth);

  String get _userId => _auth.currentUser?.uid ?? '';

  Future<List<EmotionModel>> readEmotionsByDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
    final snapshot = await _firestore
        .collection('users')
        .doc(_userId)
        .collection('emotions')
        .where('date', isGreaterThanOrEqualTo: startOfDay)
        .where('date', isLessThanOrEqualTo: endOfDay)
        .get();

    var list = snapshot.docs.map((doc) => EmotionModel.fromDoc(doc)).toList();

    return list;
  }

  Stream<List<EmotionModel>> watchEmotionsByDate(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
    return _firestore
        .collection('users')
        .doc(_userId)
        .collection('emotions')
        .where('date', isGreaterThanOrEqualTo: startOfDay)
        .where('date', isLessThanOrEqualTo: endOfDay)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => EmotionModel.fromDoc(doc)).toList());
  }

  Future<void> createEmotion(EmotionModel emotion) async {
    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('emotions')
        .add(emotion.toMap());
  }

  Future<void> updateEmotion(EmotionModel emotion) async {
    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('emotions')
        .doc(emotion.id)
        .update(emotion.toMap());
  }

  Future<void> deleteEmotion(String emotionId) async {
    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('emotions')
        .doc(emotionId)
        .delete();
  }

  // New batch method for date ranges
  Future<List<EmotionModel>> readEmotionsByDateRange(
      DateTime startDate, DateTime endDate) async {
    final startOfRange =
        DateTime(startDate.year, startDate.month, startDate.day);
    final endOfRange =
        DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);

    final snapshot = await _firestore
        .collection('users')
        .doc(_userId)
        .collection('emotions')
        .where('date', isGreaterThanOrEqualTo: startOfRange)
        .where('date', isLessThanOrEqualTo: endOfRange)
        .get();

    return snapshot.docs.map((doc) => EmotionModel.fromDoc(doc)).toList();
  }

  Future<void> deleteAllEmotions() async {
    final batch = _firestore.batch();
    final emotions = await _firestore
        .collection('users')
        .doc(_userId)
        .collection('emotions')
        .get();
    for (final doc in emotions.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  Future<void> createMultipleEmotions(List<EmotionModel> emotions) async {
    final batch = _firestore.batch();
    for (final emotion in emotions) {
      final docRef = _firestore
          .collection('users')
          .doc(_userId)
          .collection('emotions')
          .doc();
      batch.set(docRef, emotion.toMap());
    }
    await batch.commit();
  }
}
