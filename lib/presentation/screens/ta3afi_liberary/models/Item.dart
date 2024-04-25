import 'Content.dart';

class Item {
  Item({required this.content});

  Content? content;

  factory Item.fromJson(Map<String, dynamic> json) => Item(
        content: Content.fromJson(json["fields"]),
      );
  Map<String, dynamic> toJson() => {
        "fields": content?.toJson(),
      };
}
