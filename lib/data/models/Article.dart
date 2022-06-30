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

  Article.fromMap(Map<String, dynamic> snapshot) {
    title = snapshot['title'];
    author = snapshot['author'];
    date = snapshot['date'];
    timeToRead = snapshot['timeToRead'];
    body = snapshot['postBody'];
  }
}
