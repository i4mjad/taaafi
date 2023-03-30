import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_app_3/data/models/Note.dart';
import 'package:reboot_app_3/di/container.dart';
import 'package:reboot_app_3/repository/notes_repository.dart';

class NoteViewModel extends StateNotifier<List<Note>> {
  final INotesRepository _noteRepository;

  NoteViewModel()
      : _noteRepository = getIt<INotesRepository>(),
        super([]) {
    _noteRepository.getNotes().listen((notes) => state = notes);
  }

  getNotes() async {
    return await _noteRepository.getNotes();
  }

  getNote(String id) async {
    return await _noteRepository.get(id);
  }

  updateNote(Note note) async {
    await _noteRepository.update(note);
  }

  deleteNote(String noteId) async {
    await _noteRepository.delete(noteId);
  }

  Future<void> addNote({
    String title,
    String body,
  }) async {
    final newNote = Note(
      title: title,
      body: body,
      timestamp: DateTime.now(),
    );
    await _noteRepository.add(newNote);
  }
}
