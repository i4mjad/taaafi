import 'cursor_content.dart';

class CursorContentList {
  final String id;
  final String iconName;
  final bool isActive;
  final bool isFeatured;
  final List<CursorContent> contents;
  final String description;
  final String? descriptionAr;
  final String name;
  final String? nameAr;

  const CursorContentList({
    required this.id,
    required this.iconName,
    required this.isActive,
    required this.isFeatured,
    required this.contents,
    required this.description,
    this.descriptionAr,
    required this.name,
    this.nameAr,
  });

  factory CursorContentList.fromJson(Map<String, dynamic> json) {
    return CursorContentList(
      id: json['id'] as String,
      iconName: json['iconName'] as String,
      isActive: json['isActive'] as bool,
      isFeatured: json['isFeatured'] as bool,
      contents: (json['contents'] as List)
          .map((e) => CursorContent.fromJson(e as Map<String, dynamic>))
          .toList(),
      description: json['description'] as String,
      descriptionAr: json['descriptionAr'] as String?,
      name: json['name'] as String,
      nameAr: json['nameAr'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'iconName': iconName,
      'isActive': isActive,
      'isFeatured': isFeatured,
      'contents': contents.map((e) => e.toJson()).toList(),
      'description': description,
      'descriptionAr': descriptionAr,
      'name': name,
      'nameAr': nameAr,
    };
  }
}
