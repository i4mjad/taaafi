import 'package:cloud_firestore/cloud_firestore.dart';

class Note {
  dynamic id;
  dynamic title;
  dynamic body;
  dynamic timestamp;

  Note({
    this.title,
    this.body,
    this.timestamp,
  });

  void _setId(String id) {
    this.id = id;
  }

  factory Note.fromMap(Map<String, dynamic> map, String id) {
    var note = Note(
      title: map['title'],
      body: map['body'],
      timestamp: map['timestamp'] != null
          ? (map['timestamp'] as Timestamp).toDate()
          : null,
    );
    note._setId(id);
    return note;
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'body': body,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
