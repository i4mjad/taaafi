import 'package:cloud_firestore/cloud_firestore.dart';

class Article {
  String title;
  String author;
  String timeToRead;
  String body;
  String date;

  Article(
    this.title,
    this.author,
    this.timeToRead,
    this.date,
    this.body,
  );

  Article.fromMap(DocumentSnapshot snapshot) {
    title = snapshot['title'];
    author = snapshot['author'];
    date = snapshot['date'];
    timeToRead = snapshot['timeToRead'];
    body = snapshot['postBody'];
  }
}
