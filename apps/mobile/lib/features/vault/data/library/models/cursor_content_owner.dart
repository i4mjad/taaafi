import 'package:cloud_firestore/cloud_firestore.dart';

class CursorContentOwner {
  final String id;
  final String name;
  final String? nameAr;
  final String source;
  final bool isActive;

  const CursorContentOwner({
    required this.id,
    required this.name,
    this.nameAr,
    required this.source,
    required this.isActive,
  });

  factory CursorContentOwner.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CursorContentOwner(
      id: doc.id,
      name: data['ownerName'] as String,
      nameAr: data['ownerNameAr'] as String?,
      source: data['ownerSource'] as String,
      isActive: data['isActive'] as bool,
    );
  }

  factory CursorContentOwner.fromJson(Map<String, dynamic> json) {
    return CursorContentOwner(
      id: json['id'] as String,
      name: json['name'] as String,
      nameAr: json['nameAr'] as String?,
      source: json['source'] as String,
      isActive: json['isActive'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'nameAr': nameAr,
      'source': source,
      'isActive': isActive,
    };
  }
}
