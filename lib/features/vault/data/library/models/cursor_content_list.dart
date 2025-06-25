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
}
