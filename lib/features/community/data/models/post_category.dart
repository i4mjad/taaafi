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

  const PostCategory({
    required this.id,
    required this.name,
    required this.nameAr,
    required this.iconName,
    required this.colorHex,
    required this.isActive,
    required this.sortOrder,
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
