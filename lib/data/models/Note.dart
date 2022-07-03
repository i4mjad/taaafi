class Note {
  dynamic id;
  dynamic title;
  dynamic body;
  dynamic timestamp;

  Note(this.body, this.title, this.timestamp);

  Note.fromMap(Map<String, dynamic> snapshot) {
    id = snapshot['id'];
    title = snapshot["title"];
    body = snapshot["body"];
    timestamp = snapshot["timestamp"];
  }
}
