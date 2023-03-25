import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:reboot_app_3/data/models/Note.dart';

abstract class INotesRepository {
  Stream<List<Note>> getnotes();

  Future<void> add(Note note);
  Future<void> update(Note note);
  Future<void> delete(String noteId);
  Future<Note> get(String noteId);
}

class FirebaseNotesRepository implements INotesRepository {
  final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;
  //TODO: extract this to a seperate repository.
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  CollectionReference get _userNotesCollection => _firebaseFirestore
      .collection('users')
      .doc(_firebaseAuth.currentUser.uid)
      .collection('userNotes');

  @override
  Stream<List<Note>> getnotes() {
    return _userNotesCollection.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Note.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  @override
  Future<void> add(Note note) async {
    await _userNotesCollection.add({
      'title': note.title,
      'body': note.body,
      'timestamp': DateTime.now().toUtc()
    });
  }

  @override
  Future<void> delete(String noteId) async {
    await _userNotesCollection.doc(noteId).delete();
  }

  @override
  Future<void> update(Note note) async {
    var data = {
      "title": note.title,
      "body": note.body,
    };

    await _userNotesCollection.doc(note.noteId).update(data);
  }

  @override
  Future<Note> get(String noteId) async {
    var document = await _userNotesCollection.doc(noteId).get();
    return Note.fromMap(document.data(), document.id);
  }
}
