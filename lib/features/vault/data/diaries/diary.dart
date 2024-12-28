class Diary {
  final String id;
  final String title;
  final String plainText;
  final DateTime date;
  final List<dynamic>? formattedContent;
  final DateTime? updatedAt;

  Diary(
    this.id,
    this.title,
    this.plainText,
    this.date, {
    this.formattedContent,
    this.updatedAt,
  });

  // Update toJson to handle List directly
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'plainText': plainText,
        'date': date.toIso8601String(),
        'formattedContent': formattedContent,
        'updatedAt': updatedAt?.toIso8601String(),
      };

  // Update fromJson to handle List directly
  factory Diary.fromJson(Map<String, dynamic> json) => Diary(
        json['id'] as String,
        json['title'] as String,
        json['plainText'] as String,
        DateTime.parse(json['date'] as String),
        formattedContent: json['formattedContent'] as List<dynamic>?,
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'] as String)
            : null,
      );
}
