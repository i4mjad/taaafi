import 'package:cloud_firestore/cloud_firestore.dart';

class CursorContentType {
  final String id;
  final String name;
  final String iconName;
  final bool isActive;

  const CursorContentType({
    required this.id,
    required this.name,
    required this.iconName,
    required this.isActive,
  });

  factory CursorContentType.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CursorContentType(
      id: doc.id,
      name: data['contentTypeName'] as String,
      iconName: data['contentTypeIconName'] as String,
      isActive: data['isActive'] as bool,
    );
  }
}
