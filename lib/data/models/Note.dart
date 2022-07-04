class Note {
  dynamic noteId;
  dynamic title;
  dynamic body;
  dynamic timestamp;

  Note(this.body, this.title, this.timestamp);

  Note.fromMap(Map<String, dynamic> snapshot, id) {
    noteId = id;
    title = snapshot["title"];
    body = snapshot["body"];
    timestamp = snapshot["timestamp"];
  }
}
