class BlogPost {
// ignore: non_constant_identifier_names
  BlogPost(
      {this.id,
      this.title,
      this.body,
      this.slug,
      this.createdAt,
      this.updatedAt,
      this.categoryId});

  final int id;
  final String title;
  final String body;
  final String slug;
  // ignore: non_constant_identifier_names
  final String createdAt;
  // ignore: non_constant_identifier_names
  final String updatedAt;
  final String categoryId;

  factory BlogPost.fromJson(Map<String, dynamic> json) {
    return BlogPost(
      id: json["id"] as int,
      title: json["title"] as String,
      body: json["body"] as String,
      slug: json["contentOwner"] as String,
      createdAt: json["created_at"] as String,
      updatedAt: json["updatedAt"] as String,
      categoryId: json["category_id"] as String,
    );
  }
}
