import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
          .map((doc) => Diary.fromFirestore(doc.id, doc.data()))
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

      return Diary.fromFirestore(doc.id, doc.data()!);
    } catch (e) {
      throw Exception('Failed to fetch diary: $e');
    }
  }

  @override
  Future<void> updateDiary(String diaryId, Diary diary) async {
    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('userNotes')
          .doc(diaryId)
          .update(diary.toFirestore());
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
          .add(diary.toFirestore());
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
