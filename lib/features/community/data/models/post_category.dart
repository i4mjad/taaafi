import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class PostCategory {
  final String id;
  final String name;
  final String nameAr;
  final String iconName;
  final String colorHex;
  final bool isActive;
  final int sortOrder;
  final bool isForAdminOnly;

  const PostCategory({
    required this.id,
    required this.name,
    required this.nameAr,
    required this.iconName,
    required this.colorHex,
    required this.isActive,
    required this.sortOrder,
    this.isForAdminOnly = false,
  });

  factory PostCategory.fromJson(Map<String, dynamic> json) {
    return PostCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      nameAr: json['nameAr'] as String,
      iconName: json['iconName'] as String,
      colorHex: json['colorHex'] as String,
      isActive: json['isActive'] as bool? ?? true,
      sortOrder: json['sortOrder'] as int? ?? 0,
      isForAdminOnly: json['isForAdminOnly'] as bool? ?? false,
    );
  }

  /// Factory method for creating PostCategory from Firestore document
  /// where the document ID is auto-generated and not stored as a field
  factory PostCategory.fromFirestore(
      String documentId, Map<String, dynamic> data) {
    return PostCategory(
      id: documentId, // Use the document ID as the category ID
      name: data['name'] as String,
      nameAr: data['nameAr'] as String,
      iconName: data['iconName'] as String,
      colorHex: data['colorHex'] as String,
      isActive: data['isActive'] as bool? ?? true,
      sortOrder: data['sortOrder'] as int? ?? 0,
      isForAdminOnly: data['isForAdminOnly'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'nameAr': nameAr,
      'iconName': iconName,
      'colorHex': colorHex,
      'isActive': isActive,
      'sortOrder': sortOrder,
      'isForAdminOnly': isForAdminOnly,
    };
  }

  /// Convert to Firestore data (excludes the id field since it's the document ID)
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'nameAr': nameAr,
      'iconName': iconName,
      'colorHex': colorHex,
      'isActive': isActive,
      'sortOrder': sortOrder,
      'isForAdminOnly': isForAdminOnly,
    };
  }
}

// Extension to get the icon from iconName
extension PostCategoryExtension on PostCategory {
  IconData get icon {
    switch (iconName.toLowerCase()) {
      case 'chat':
        return LucideIcons.messageCircle;
      case 'help':
        return LucideIcons.helpCircle;
      case 'lightbulb':
        return LucideIcons.lightbulb;
      case 'support':
        return LucideIcons.lifeBuoy;
      case 'group':
        return LucideIcons.users;
      case 'question':
        return LucideIcons.helpCircle;
      case 'discussion':
        return LucideIcons.messagesSquare;
      case 'tips':
        return LucideIcons.zap;
      default:
        return LucideIcons.tag;
    }
  }

  Color get color {
    try {
      return Color(int.parse(colorHex.replaceAll('#', '0xFF')));
    } catch (e) {
      return Colors.grey;
    }
  }

  String getDisplayName(String languageCode) {
    return languageCode == 'ar' ? nameAr : name;
  }
}
