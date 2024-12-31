import 'cursor_content_category.dart';
import 'cursor_content_owner.dart';
import 'cursor_content_type.dart';

class CursorContent {
  final String id;
  final CursorContentCategory category;
  final String language;
  final String link;
  final String name;
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
    required this.owner,
    required this.type,
    required this.createdAt,
    required this.updatedAt,
    required this.isActive,
    required this.isDeleted,
  });
}
