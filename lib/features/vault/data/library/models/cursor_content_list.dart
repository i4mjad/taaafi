import 'cursor_content.dart';

class CursorContentList {
  final String id;
  final String iconName;
  final bool isActive;
  final bool isFeatured;
  final List<CursorContent> contents;
  final String description;
  final String name;

  const CursorContentList({
    required this.id,
    required this.iconName,
    required this.isActive,
    required this.isFeatured,
    required this.contents,
    required this.description,
    required this.name,
  });
}
