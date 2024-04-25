import 'package:cloud_firestore/cloud_firestore.dart';

class ExploreContent {
  String? title;
  String? author;
  String? timeToRead;
  String? body;
  String? date;
  String? type;

  ExploreContent(
    this.title,
    this.author,
    this.timeToRead,
    this.date,
    this.body,
    this.type,
  );

  factory ExploreContent.fromMap(DocumentSnapshot snapshot) {
    return ExploreContent(
        snapshot['title'],
        snapshot['author'],
        snapshot['date'],
        snapshot['timeToRead'],
        snapshot['postBody'],
        snapshot['type']);
  }
}
