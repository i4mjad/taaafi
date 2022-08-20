import 'package:cloud_firestore/cloud_firestore.dart';

class ExploreContent {
  String title;
  String author;
  String timeToRead;
  String body;
  String date;

  ExploreContent(
    this.title,
    this.author,
    this.timeToRead,
    this.date,
    this.body,
  );

  ExploreContent.fromMap(DocumentSnapshot snapshot) {
    title = snapshot['title'];
    author = snapshot['author'];
    date = snapshot['date'];
    timeToRead = snapshot['timeToRead'];
    body = snapshot['postBody'];
  }
}
