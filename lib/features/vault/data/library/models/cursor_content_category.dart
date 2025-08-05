import 'package:cloud_firestore/cloud_firestore.dart';

class CursorContentCategory {
  final String id;
  final String name;
  final String? nameAr;
  final String iconName;
  final bool isActive;

  const CursorContentCategory({
    required this.id,
    required this.name,
    this.nameAr,
    required this.iconName,
    required this.isActive,
  });

  factory CursorContentCategory.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CursorContentCategory(
      id: doc.id,
      name: data['categoryName'] as String,
      nameAr: data['categoryNameAr'] as String?,
      iconName: data['contentCategoryIconName'] as String,
      isActive: data['isActive'] as bool,
    );
  }

  factory CursorContentCategory.fromJson(Map<String, dynamic> json) {
    return CursorContentCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      nameAr: json['nameAr'] as String?,
      iconName: json['iconName'] as String,
      isActive: json['isActive'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'nameAr': nameAr,
      'iconName': iconName,
      'isActive': isActive,
    };
  }
}
