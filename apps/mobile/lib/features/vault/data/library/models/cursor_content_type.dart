import 'package:cloud_firestore/cloud_firestore.dart';

class CursorContentType {
  final String id;
  final String name;
  final String? nameAr;
  final String iconName;
  final bool isActive;

  const CursorContentType({
    required this.id,
    required this.name,
    this.nameAr,
    required this.iconName,
    required this.isActive,
  });

  factory CursorContentType.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CursorContentType(
      id: doc.id,
      name: data['contentTypeName'] as String,
      nameAr: data['contentTypeNameAr'] as String?,
      iconName: data['contentTypeIconName'] as String,
      isActive: data['isActive'] as bool,
    );
  }

  factory CursorContentType.fromJson(Map<String, dynamic> json) {
    return CursorContentType(
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
