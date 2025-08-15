import 'cursor_content_category.dart';
import 'cursor_content_owner.dart';
import 'cursor_content_type.dart';

class CursorContent {
  final String id;
  final CursorContentCategory category;
  final String language;
  final String link;
  final String name;
  final String? nameAr;
  final CursorContentOwner owner;
  final CursorContentType type;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final bool isDeleted;

  const CursorContent({
    required this.id,
    required this.category,
    required this.language,
    required this.link,
    required this.name,
    this.nameAr,
    required this.owner,
    required this.type,
    required this.createdAt,
    required this.updatedAt,
    required this.isActive,
    required this.isDeleted,
  });

  factory CursorContent.fromJson(Map<String, dynamic> json) {
    return CursorContent(
      id: json['id'] as String,
      category: CursorContentCategory.fromJson(json['category'] as Map<String, dynamic>),
      language: json['language'] as String,
      link: json['link'] as String,
      name: json['name'] as String,
      nameAr: json['nameAr'] as String?,
      owner: CursorContentOwner.fromJson(json['owner'] as Map<String, dynamic>),
      type: CursorContentType.fromJson(json['type'] as Map<String, dynamic>),
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(json['updatedAt'] as int),
      isActive: json['isActive'] as bool,
      isDeleted: json['isDeleted'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category.toJson(),
      'language': language,
      'link': link,
      'name': name,
      'nameAr': nameAr,
      'owner': owner.toJson(),
      'type': type.toJson(),
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'isActive': isActive,
      'isDeleted': isDeleted,
    };
  }
}
