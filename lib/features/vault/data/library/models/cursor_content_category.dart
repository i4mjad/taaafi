import 'package:cloud_firestore/cloud_firestore.dart';

class CursorContentCategory {
  final String id;
  final String name;
  final String iconName;
  final bool isActive;

  const CursorContentCategory({
    required this.id,
    required this.name,
    required this.iconName,
    required this.isActive,
  });

  factory CursorContentCategory.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CursorContentCategory(
      id: doc.id,
      name: data['categoryName'] as String,
      iconName: data['contentCategoryIconName'] as String,
      isActive: data['isActive'] as bool,
    );
  }
}
