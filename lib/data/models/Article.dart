class Article {
  String title;
  String author;
  String timeToRead;
  String breif;
  String body;

  Article(
    this.title,
    this.author,
    this.timeToRead,
    this.breif,
    this.body,
  );

  Article.fromMap(Map<String, dynamic> snapshot) {
    title = snapshot['title'];
    author = snapshot['author'];
    timeToRead = snapshot['timeToRead'];
    breif = snapshot['breif'];
    body = snapshot['postBody'];
  }
}
