import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:reboot_app_3/data/models/Note.dart';

abstract class INotesRepository {
  Stream<List<Note>> getNotes();
  Future<void> add(Note note);
  Future<void> update(Note note);
  Future<void> delete(String noteId);
  Future<Note> get(String noteId);
}

class FirebaseNotesRepository implements INotesRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _notesController = StreamController<List<Note>>.broadcast();

  @override
  Stream<List<Note>> getNotes() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      _notesController.addError('No user signed in');
      return _notesController.stream;
    }

    final notesRef =
        _firestore.collection('users').doc(userId).collection('userNotes');
    notesRef.snapshots().listen((snap) {
      final notes =
          snap.docs.map((doc) => Note.fromMap(doc.data(), doc.id)).toList();
      _notesController.add(notes);
    });

    return _notesController.stream;
  }

  @override
  Future<void> add(Note note) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) throw Exception('No user signed in');

    final notesRef =
        _firestore.collection('users').doc(userId).collection('userNotes');
    await notesRef.add(note.toMap());
  }

  @override
  Future<void> update(Note note) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) throw Exception('No user signed in');

    final notesRef =
        _firestore.collection('users').doc(userId).collection('userNotes');
    await notesRef.doc(note.id).update(note.toMap());
  }

  @override
  Future<void> delete(String id) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) throw Exception('No user signed in');

    final notesRef =
        _firestore.collection('users').doc(userId).collection('userNotes');
    await notesRef.doc(id).delete();
  }

  @override
  Future<Note> get(String id) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) throw Exception('No user signed in');

    final notesRef =
        _firestore.collection('users').doc(userId).collection('userNotes');
    final doc = await notesRef.doc(id).get();

    if (!doc.exists) throw Exception('Note not found');

    return Note.fromMap(doc.data() as Map<String, dynamic>, id);
  }

  void dispose() {
    _notesController.close();
  }
}
